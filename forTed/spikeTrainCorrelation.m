function spikeTrainCorrelation(optPath, workerId, totalWorkers)
% Spike train cross-correlation with LRU cache for overlapping units
% Args:
%   optPath: Path to the options .mat file
%   workerId: Worker ID for parallel processing
%   totalWorkers: Total number of workers

% Initialize global variables
global startTime currentWorkerId
startTime = tic;
currentWorkerId = workerId;

% Load configuration options
options = load(optPath).opt;
pairsToProcess = options.pairs;
binSize = 4;%options.binning;
centralWindowSize_ms = 10;%options.central_window;
baselineMaxLag_ms = 1000;%options.max_lag;

% Assign pairs to the current worker
pairGroups = generatePairGroups(max(pairsToProcess(:)), totalWorkers);
workerPairs = pairGroups{workerId};
options.pairs = workerPairs;

% Exit early if no pairs assigned
if isempty(workerPairs)
    logMessage('No pairs to process. Skipping...\n');
    saveResults(options, workerId, [], [], [], [], 'No pairs to process.');
    return;
end

% Open the spikes file and initialize the cache
logMessage('Opening spikes matfile: %s\n', options.spike_path);
spikeCache = containers.Map('KeyType', 'double', 'ValueType', 'any');
lruQueue = []; % LRU queue for cache eviction
cacheLimit = 2;

logMessage('Processing %d pairs out of %d total pairs.\n', size(workerPairs, 1), size(options.pairs, 1));

% Process each pair assigned to this worker
for pairIdx = 1:size(workerPairs, 1)
    logMessage('Progress: Pair %d of %d\n', pairIdx, size(workerPairs, 1));
    neuronPair = workerPairs(pairIdx, :);

    % Load or retrieve spike trains for the neuron pair
    [spikesNeuron1, lruQueue] = loadFromCache(spikeCache, lruQueue, neuronPair(1), options.spike_path, cacheLimit);
    [spikesNeuron2, lruQueue] = loadFromCache(spikeCache, lruQueue, neuronPair(2), options.spike_path, cacheLimit);

    if pairIdx == 1
        numSessions = size(spikesNeuron1.spikes,2);
        numTimeGroups = ceil(numSessions / binSize);
        numNeurons = max(pairsToProcess(:));
        zscorePosMax = NaN(numNeurons, numNeurons, numTimeGroups);
        zscoreNegMax = NaN(numNeurons, numNeurons, numTimeGroups);
        lagPosMax = NaN(numNeurons, numNeurons, numTimeGroups);
        lagNegMax = NaN(numNeurons, numNeurons, numTimeGroups);
        binStarts = (1:binSize:numSessions)';
        sessionBins = [binStarts,binStarts + binSize - 1];
        sessionBins(sessionBins > numSessions) = numSessions;
        baselineMaxLag = baselineMaxLag_ms/milliseconds(spikesNeuron2.tbin);
        centralWindowSize = centralWindowSize_ms/milliseconds(spikesNeuron2.tbin);
    end

    % Process in time bins
    for timeGroupIdx = 1:numTimeGroups
        % Define the time segment
        firstSession = sessionBins(timeGroupIdx,1);
        lastSession = sessionBins(timeGroupIdx,2);

        % Extract spikes for the current segment
        segmentSpikesNeuron1 = [spikesNeuron1.spikes{firstSession:lastSession}];
        segmentSpikesNeuron2 = [spikesNeuron2.spikes{firstSession:lastSession}];

        % Compute cross-correlation
        [crossCorr, lagValues_samp] = xcorr(segmentSpikesNeuron2, segmentSpikesNeuron1, baselineMaxLag);
        lagValues = lagValues_samp * milliseconds(spikesNeuron2.tbin);        
        
        % Define baseline lag ranges
        baselinePosLags = 10:baselineMaxLag;
        baselineNegLags = -baselinePosLags(end:-1:1);
        baselineIdxs = ismember(lagValues, [baselineNegLags, baselinePosLags]);

        % Calculate baseline statistics
        baselineValues = crossCorr(baselineIdxs);
        % Under the Poisson model, the mean of the baseline is our lambda
        lambda = mean(baselineValues);
        if lambda < 2
            continue
        end

        % Positive lags
        [zscorePosMax(neuronPair(1), neuronPair(2), timeGroupIdx), ...
            lagPosMax(neuronPair(1), neuronPair(2), timeGroupIdx)] = ...
            computeExtrema(crossCorr, lagValues, [0 centralWindowSize_ms], lambda, 3);

        % Negative lags
        [zscoreNegMax(neuronPair(1), neuronPair(2), timeGroupIdx), ...
            lagNegMax(neuronPair(1), neuronPair(2), timeGroupIdx)] = ...
            computeExtrema(crossCorr, lagValues, [-centralWindowSize_ms 0], lambda, 3);
    end
end

% Save results
saveResults(options, workerId, zscorePosMax, zscoreNegMax, lagPosMax, lagNegMax);
logMessage('Results saved successfully.\n');
end


function [zFinal, lagFinal] = computeExtrema(ccf, lags, lagRange, lambda, windowSize)
% computeExtremaPoissonMinMaxPeaks
%
%   [zFinal, lagFinal] = computeExtremaPoissonMinMaxPeaks(ccf, lags, lagRange, lambda, windowSize)
%
%   This function computes extreme z-scores for cross-correlation counts using a Poisson model.
%
%   For excitation (positive deviations):  
%       For each bin in the specified lag range (with |lag| < 6), if the count exceeds
%       lambda, compute an upper-tail p-value:
%           p = 1 - poisscdf(x-1, lambda)
%       and convert it to a z-score with norminv.
%
%   For inhibition (negative deviations):  
%       A sliding window (of size windowSize) is applied. For each window, if the sum of
%       counts is less than the expected sum (windowSize*lambda), compute a lower-tail
%       p-value:
%           p = poisscdf(windowSum, windowSize*lambda)
%       and convert that to a z-score.
%
%   Then, the function uses findpeaks to pick out local extrema on both sides.
%
%   Inputs:
%     ccf        - Cross-correlation counts (vector)
%     lags       - Corresponding lag values (vector)
%     lagRange   - Two-element vector [minLag maxLag] specifying the lag range of interest
%     lambda     - Expected Poisson rate per bin (baseline estimate)
%     windowSize - Number of bins for the sliding-window inhibition test (e.g., 3)
%
%   Outputs:
%     zFinal     - Final extreme z-score (positive for excitation, negative for inhibition;
%                  if both are significant, returns NaN to indicate ambiguity)
%     lagFinal   - Lag at which the extreme effect is observed

%% Restrict to specified lag range and |lag| < 6
idx = iswithin(lags, lagRange');  % get indices in lagRange
lags_sub = lags(idx);
ccf_sub  = ccf(idx);

Np = 5;
Nn = 4;
biasP = sqrt(2 * log(Np));
biasN = sqrt(2 * log(Nn));

% Further restrict to |lag| < 6
% validIdx = iswithin(abs(lags_sub), 1, 6);
% lags_sub = lags_sub(validIdx);
% ccf_sub  = ccf_sub(validIdx);

%% Positive side: per-bin z-scores for excitation
zPos = zeros(size(ccf_sub));
for i = 1:length(ccf_sub)
    x = ccf_sub(i);
    if x > lambda
        % Compute upper-tail p-value for count x
        p = 1 - poisscdf(x-1, lambda);
        p = max(p, 1e-10); % avoid p==0
        % Convert to z-score (small p gives high positive z)
        zPos(i) = norminv(1 - p);
    else
        zPos(i) = 0;
    end
end

% Use findpeaks to locate local positive extrema
[posPeaks, posPeakIdx] = findpeaks([0 zPos]);
posLags = lags_sub(posPeakIdx - 1);

validIdxs = iswithin(posLags,1,5);
posLags = posLags(validIdxs);
posPeaks = posPeaks(validIdxs);

%% Negative side: sliding window for inhibition
nBins = length(ccf_sub);
if nBins < windowSize
    % Not enough bins for a sliding window: return empty
    zNeg = [];
    negLags = [];
else
    nWindows = nBins - windowSize + 1;
    zNeg = zeros(nWindows, 1);
    negLags = zeros(nWindows, 1);
    
    for i = 1:nWindows
        windowData = ccf_sub(i:i+windowSize-1);
        windowSum = sum(windowData);
        expectedWindow = windowSize * lambda;
        
        if windowSum < expectedWindow
            % Compute lower-tail p-value for window sum
            pNeg = poisscdf(windowSum, expectedWindow);
            pNeg = max(pNeg, 1e-10);
            zTemp = norminv(pNeg);
            % Ensure zTemp is negative; if not, set to zero.
            if zTemp < 0
                zNeg(i) = zTemp;
            else
                zNeg(i) = 0;
            end
        else
            zNeg(i) = 0;
        end
        % Representative lag for the window: the center of the window.
        negLags(i) = mean(lags_sub(i:i+windowSize-1));
    end
end

% Use findpeaks to locate local minima in the negative side.
% We do this by applying findpeaks to the negative of the zNeg vector.
if ~isempty(zNeg)
    [negPeaks, negPeakIdx] = findpeaks(-zNeg);
    % Convert back to negative z-scores:
    negPeaks = -negPeaks;
    negLags = negLags(negPeakIdx);

    validIdxs = iswithin(negLags,1,5);
    negLags = negLags(validIdxs);
    negPeaks = negPeaks(validIdxs);
else
    negPeaks = [];
    negLags = [];
end

%% Determine the extreme values
% Positive extreme
if isempty(posPeaks)
    zMaxPos = 0;
    lagMaxPos = 0;
else
    [zMaxPos, idxPos] = max(posPeaks);  % largest positive z
    lagMaxPos = posLags(idxPos);
end

% Negative extreme
if isempty(negPeaks)
    zMaxNeg = 0;
    lagMaxNeg = 0;
else
    % For negative z, the most extreme is the minimum value.
    [zMaxNeg, idxNeg] = min(negPeaks);
    lagMaxNeg = negLags(idxNeg);
end

%% Threshold logic to choose the final extreme
threshold = 3; % significance threshold

% If both extremes are zero, return zero.
if (zMaxPos == 0 && zMaxNeg == 0)
    zFinal = 0;
    lagFinal = 0;
elseif ~all([abs(zMaxPos), abs(zMaxNeg)] > threshold)
    % If only one extreme is above threshold, choose the dominant one.
    if abs(zMaxNeg) > abs(zMaxPos) || zMaxPos == 0
        zFinal = zMaxNeg + biasN;
        lagFinal = lagMaxNeg;
    else
        zFinal = zMaxPos - biasP;
        lagFinal = lagMaxPos;
    end
else
    % If both exceed threshold, the result is ambiguous.
    zFinal = NaN;
    lagFinal = NaN;
end

if abs(zFinal) < biasP
    zFinal = 0;
    lagFinal = 0;
end

[zFinal, lagFinal]
end

function [spikes, queue] = loadFromCache(cache, queue, unitId, spikePath, maxCacheSize)
% Retrieve spikes from cache or load from file if not cached
try
    if isKey(cache, unitId)
        spikes = cache(unitId);
        queue(queue == unitId) = [];
        queue = [queue, unitId]; % Update LRU queue
    else
        spikes = load(fullfile(spikePath, sprintf('spikes_%d.mat', unitId))).sp;
        cache(unitId) = spikes;
        queue = [queue, unitId];
        if numel(queue) > maxCacheSize
            remove(cache, queue(1)); % Evict least recently used item
            queue(1) = [];
        end
    end
catch ME
    error('Error loading spikes for unit %d: %s', unitId, ME.message);
end
end

function saveResults(options, workerId, zscorePos, zscoreNeg, lagPos, lagNeg, message)
% Save results to a .mat file
results.options = options;
results.zscorePos = zscorePos;
results.zscoreNeg = zscoreNeg;
results.lagPos = lagPos;
results.lagNeg = lagNeg;
if exist('message', 'var')
    results.message = message;
end
if ~isfolder(options.save_path)
    mkdir(options.save_path);
end
save(fullfile(options.save_path, sprintf('results_%s_%d.mat', options.name, workerId)), 'results', '-v7.3');
end

function logMessage(message, varargin)
% Log worker-specific messages with timestamps
global startTime currentWorkerId;
fprintf('[%.2fs] [Worker %d] %s', toc(startTime), currentWorkerId, sprintf(message, varargin{:}));
end
