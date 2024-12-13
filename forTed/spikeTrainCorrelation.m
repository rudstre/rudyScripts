function spikeTrainCorrelation(optPath, wid, w_tot)
% Spike train cross-correlation with LRU cache for overlapping units
% Args:
%   optPath: Path to the options .mat file
%   wid: Worker ID for parallel processing
%   w_tot: Total number of workers

% Start timer
global startTime wid
startTime = tic;

% Load options
opt = load(optPath).opt;
pairs = opt.pairs;
binning = opt.binning;
central_window = opt.central_window;
thr_spikes = opt.thr_spikes;
max_lag = opt.max_lag;
num_random_lags = opt.num_random_lags;
num_sessions = opt.nsessions;

% Generate groups of pairs based on worker ID
groups = generatePairGroups(max(pairs(:)), w_tot);
pairs = groups{wid};

% Skip if no pairs to process
if isempty(pairs)
    workerPrint('No pairs to process. Skipping...\n');
    saveResults(opt, wid, [], [], [], [], 'No pairs to process.');
    return;
end

% Open the spikes matfile for read-only access
workerPrint('Opening spikes matfile: %s\n', opt.spike_path);

% Initialize spike cache and LRU queue
spikeCache = containers.Map('KeyType', 'double', 'ValueType', 'any');
lruQueue = []; % Stores the order of access (most recent at the end)
cacheLimit = 2;

% Initialize output arrays using NaN to handle absent data
num_cells = max(pairs(:));
num_groups = ceil(num_sessions / binning);
max_zscore_pos = NaN(num_cells, num_cells, num_groups);
max_zscore_neg = NaN(num_cells, num_cells, num_groups);
max_zscore_lag_pos = NaN(num_cells, num_cells, num_groups);
max_zscore_lag_neg = NaN(num_cells, num_cells, num_groups);

% Log progress
workerPrint('Processing %d pairs out of %d total pairs.\n', size(pairs, 1), size(opt.pairs, 1));

% Binned recording length (in samples)
ul = seconds(opt.timePerRec) * 1000 * binning;

% Iterate over pairs of neurons
for pair_num = 1:size(pairs, 1)
    workerPrint('Progress: Pair %d of %d\n', pair_num, size(pairs, 1));
    pair = pairs(pair_num, :);

    % Retrieve or load spike train for unit 1
    [spikes1_full, lruQueue] = getFromCache(...
        spikeCache, lruQueue, pair(1), opt.spike_path, cacheLimit);

    % Retrieve or load spike train for unit 2
    [spikes2_full, lruQueue] = getFromCache(...
        spikeCache, lruQueue, pair(2), opt.spike_path, cacheLimit);

    % Process data in time bins
    for group = 1:num_groups
        % Define segment indices for the current group
        idx_start = ul * (group - 1) + 1;
        idx_end = min([idx_start + ul - 1, length(spikes1_full), length(spikes2_full)]);

        % Skip invalid segments
        if idx_start > idx_end
            continue;
        end

        % Extract spike segments for the current time bin
        spikes1 = spikes1_full(idx_start:idx_end);
        spikes2 = spikes2_full(idx_start:idx_end);

        % Compute cross-correlation within the specified lag window
        [ccf, lags] = xcorr(spikes1, spikes2, central_window);

        % Exclude zero lag
        non_zero_lag_indices = lags ~= 0;
        ccf_no_zero = ccf(non_zero_lag_indices);
        lags_no_zero = lags(non_zero_lag_indices);

        % Check for sufficient spike coincidences
        if sum(ccf_no_zero) < thr_spikes
            continue;
        end

        % Generate null distribution from random shifts
        random_lags = randsample([-max_lag:-central_window-1, central_window+1:max_lag], num_random_lags, true);
        null_distribution = arrayfun(@(lag) sum(circshift(spikes1, lag) .* spikes2), random_lags);

        % Calculate z-scores
        mean_null = mean(null_distribution);
        std_null = std(null_distribution);
        z_scores = (ccf_no_zero - mean_null) / std_null;

        % Find most extreme z-scores for positive and negative lags
        pos_lag_indices = lags_no_zero > 0;
        neg_lag_indices = lags_no_zero < 0;
        [~, max_pos_idx] = max(abs(z_scores(pos_lag_indices)));
        [~, max_neg_idx] = max(abs(z_scores(neg_lag_indices)));

        % Extract corresponding z-scores and lags
        z_scores_pos = z_scores(pos_lag_indices);
        z_scores_neg = z_scores(neg_lag_indices);
        lags_pos = lags_no_zero(pos_lag_indices);
        lags_neg = lags_no_zero(neg_lag_indices);

        % Store results in output arrays
        max_zscore_pos(pair(1), pair(2), group) = z_scores_pos(max_pos_idx);
        max_zscore_neg(pair(1), pair(2), group) = z_scores_neg(max_neg_idx);
        max_zscore_lag_pos(pair(1), pair(2), group) = lags_pos(max_pos_idx);
        max_zscore_lag_neg(pair(1), pair(2), group) = lags_neg(max_neg_idx);
    end
end

% Save results
saveResults(opt, wid, ...
    max_zscore_pos, max_zscore_neg, max_zscore_lag_pos, max_zscore_lag_neg);
workerPrint('Results saved successfully.\n');
end

function [spikes, lruQueue] = getFromCache(spikeCache, lruQueue, unit, spikePath, cacheLimit)
% Retrieve spike train from cache or load from file if not cached
try
    if isKey(spikeCache, unit)
        spikes = spikeCache(unit);
        % Update LRU queue
        lruQueue = [lruQueue(lruQueue ~= unit), unit];
        workerPrint('Using cached spikes for unit %d\n', unit);
    else
        % Load spike train from file
        spikes = load(...
                fullfile(spikePath,sprintf('spikes_%d',unit))...
            ).sp;
        spikeCache(unit) = spikes;

        % Add to LRU queue
        lruQueue = [lruQueue, unit];

        % Evict least recently used item if cache exceeds limit
        if numel(lruQueue) > cacheLimit
            evictUnit = lruQueue(1);
            remove(spikeCache, evictUnit);
            lruQueue(1) = [];
            workerPrint('Evicted spikes for unit %d from cache\n', evictUnit);
        end

        workerPrint('Loaded spikes for unit %d into cache\n', unit);
    end
catch ME
    error('Failed to load spike train for unit %d: %s', unit, ME.message);
end
end

function saveResults(opt, wid, zscore_pos, zscore_neg, zscore_lag_pos, zscore_lag_neg, message)
% Save results to a .mat file
results.opt = opt;
results.zscore_pos = zscore_pos;
results.zscore_neg = zscore_neg;
results.zscore_lag_pos = zscore_lag_pos;
results.zscore_lag_neg = zscore_lag_neg;
if exist('message', 'var')
    results.message = message;
end
if ~isfolder(opt.save_path)
    mkdir(opt.save_path);
end
save(fullfile(opt.save_path, sprintf('results_%s_%d', opt.name, wid)), 'results', '-v7.3');
end

function workerPrint(str, varargin)
global startTime wid;
fprintf('[%.2fs] [Worker %d] %s', toc(startTime), wid, sprintf(str, varargin{:}));
end
