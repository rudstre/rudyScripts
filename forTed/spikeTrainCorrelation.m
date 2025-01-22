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
centralWindowSize = options.central_window;
baselineMaxLag = 1000;%options.max_lag;

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
        [crossCorr, lagValues] = xcorr(segmentSpikesNeuron2,segmentSpikesNeuron1,baselineMaxLag);

        % Exclude zero lag
        nonZeroLagIdx = lagValues ~= 0;
        crossCorrNoZero = crossCorr(nonZeroLagIdx);
        lagValuesNoZero = lagValues(nonZeroLagIdx);

        % Define baseline lag ranges
        baselinePosLags = centralWindowSize:baselineMaxLag;
        baselineNegLags = -baselinePosLags(end:-1:1);
        baselineIdxs = ismember(lagValuesNoZero, [baselineNegLags, baselinePosLags]);

        % Calculate baseline statistics
        baselineValues = crossCorrNoZero(baselineIdxs);
        baselineMean = mean(baselineValues);
        baselineStd = std(baselineValues);

        % Calculate theoretical max-window extrema
        expectedMax = baselineMean + baselineStd * sqrt(2 * log(centralWindowSize));
        expectedMin = baselineMean - baselineStd * sqrt(2 * log(centralWindowSize));
        varianceExtrema = baselineStd^2 / (2 * log(centralWindowSize));

        % Positive lags
        [zscorePosMax(neuronPair(1), neuronPair(2), timeGroupIdx), ...
            lagPosMax(neuronPair(1), neuronPair(2), timeGroupIdx)] = ...
            computeExtrema(crossCorrNoZero, lagValuesNoZero, 1:centralWindowSize, expectedMax, expectedMin, varianceExtrema);

        % Negative lags
        [zscoreNegMax(neuronPair(1), neuronPair(2), timeGroupIdx), ...
            lagNegMax(neuronPair(1), neuronPair(2), timeGroupIdx)] = ...
            computeExtrema(crossCorrNoZero, lagValuesNoZero, -(centralWindowSize:-1:1), expectedMax, expectedMin, varianceExtrema);
    end
end

% Save results
saveResults(options, workerId, zscorePosMax, zscoreNegMax, lagPosMax, lagNegMax);
logMessage('Results saved successfully.\n');
end


function [zFinal, lagFinal] = computeExtrema(ccf, lags, lagRange, expectedMax, expectedMin, varExtrema)
% Compute z-scores and find extrema for a specified lag range
lagIndices = ismember(lags, lagRange);          % Find indices for the specific lag range
lagValues = lags(lagIndices);                   % Extract lag values within the range
crossCorrValues = ccf(lagIndices);              % Extract cross-correlation values for the range

% Compute z-scores for positive and negative lags
zScoresPos = (crossCorrValues - expectedMax) / sqrt(varExtrema);
zScoresNeg = (crossCorrValues - expectedMin) / sqrt(varExtrema);

% Find maxima and their indices
[zMaxPos, idxMaxPos] = max(zScoresPos);         % Maximum positive z-score
[zMaxNeg, idxMaxNeg] = min(zScoresNeg);    % Maximum negative z-score (absolute value)

% Get corresponding lags
lagMaxPos = lagValues(idxMaxPos);
lagMaxNeg = lagValues(idxMaxNeg);

% Threshold for determining significance
threshold = 5;

% Check if both extrema are above the threshold
extremumCheck = [abs(zMaxPos), abs(zMaxNeg)];

if ~all(extremumCheck > threshold)
    % If not both extrema are high, return the dominant one
    if abs(zMaxNeg) > abs(zMaxPos)
        zFinal = zMaxNeg;
        lagFinal = lagMaxNeg;
    else
        zFinal = zMaxPos;
        lagFinal = lagMaxPos;
    end
else
    % If both extrema are high, do not oversimplify — return NaN
    zFinal = NaN;
    lagFinal = NaN;
end
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
