function spikeTrainCorrelationParallel(opt, numWorkers)
% Parallelized spike train correlation analysis
% Args:
%   opt: Options structure containing analysis parameters and paths
%   numWorkers: Number of workers to run in parallel

% Start a parallel pool
fprintf('Starting parallel pool with %d workers...\n', numWorkers);
pool = parpool('local', numWorkers);

% Load the spikes data once on the client (main process)
fprintf('Loading spikes data from %s...\n', opt.spike_path);
spikesData = load(opt.spike_path).spikes;
fprintf('Spikes data loaded successfully. Broadcasting to workers...\n');

% Broadcast data using parallel.pool.Constant
sharedSpikes = parallel.pool.Constant(spikesData);

% Generate groups of neuron pairs
fprintf('Generating groups of pairs for %d workers...\n', numWorkers);
groups = generatePairGroups(max(opt.pairs(:)), numWorkers);

fprintf('Groups generated successfully. Checking groups...\n');
for i = 1:numWorkers
    fprintf('Worker %d: Group size = %d\n', i, length(groups{i}));
end

% Run the computations in parallel
parfor wid = 1:numWorkers
    fprintf('[Worker %d] Starting processing...\n', wid);

    % Extract the subset of pairs for this worker
    localOpt = opt;
    localOpt.pairs = localOpt.pairs(ismember(localOpt.pairs(:, 1), groups{wid}), :);
    
    try
        filtered_units = unique(localOpt.pairs(:)); % Unique neuron indices for this worker
        test_spikes = sharedSpikes.Value(filtered_units); % Test access
        fprintf('[Worker %d] Successfully accessed sharedSpikes for %d units.\n', wid, length(filtered_units));
    catch ME
        fprintf('[Worker %d] Error accessing sharedSpikes: %s\n', wid, ME.message);
    end

    % Perform spike train correlation analysis
    processWorker(localOpt, wid, sharedSpikes.Value);

    fprintf('[Worker %d] Finished processing.\n', wid);
end

% Delete the parallel pool after computation
fprintf('All workers finished. Shutting down parallel pool...\n');
delete(pool);
end

function processWorker(opt, wid, spikes)
% Worker-specific processing function
% Args:
%   opt: Local options structure for the worker
%   wid: Worker ID
%   spikes: Spikes data shared from the client

% Parameters from options
pairs = opt.pairs;
binning = opt.binning;
central_window = opt.central_window;
thr_spikes = opt.thr_spikes;
max_lag = opt.max_lag;
num_random_lags = opt.num_random_lags;

ul = opt.timePerRec * 1000 * binning; % Binned recording length
num_cells = max(pairs(:));
num_groups = 32 / binning;

% Initialize results arrays
max_zscore_pos = NaN(num_cells, num_cells, num_groups);
max_zscore_neg = NaN(num_cells, num_cells, num_groups);
max_zscore_lag_pos = NaN(num_cells, num_cells, num_groups);
max_zscore_lag_neg = NaN(num_cells, num_cells, num_groups);

% Retrieve unique units from pairs
unique_units = unique(pairs(:));
spikes = spikes(unique_units); % Access shared data
pairs_converted = arrayfun(@(x) find(unique_units == x, 1), pairs);

% Iterate over each pair
for pair_num = 1:length(pairs)
    fprintf('[Worker %d] Processing pair %d of %d...\n', wid, pair_num, length(pairs));
    pair = pairs_converted(pair_num, :);

    % Retrieve spike trains for the current pair
    spikes1_full = spikes{pair(1)};
    spikes2_full = spikes{pair(2)};

    for group = 1:num_groups
        % Define segment indices for the current group
        idx_start = ul * (group - 1) + 1;
        idx_end = min([idx_start + ul - 1, length(spikes1_full), length(spikes2_full)]);

        % Skip invalid segments
        if idx_start > idx_end
            fprintf('[Worker %d] Skipping invalid group %d for pair %d.\n', wid, group, pair_num);
            continue;
        end

        % Extract spike segments
        spikes1 = spikes1_full(idx_start:idx_end);
        spikes2 = spikes2_full(idx_start:idx_end);

        % Compute cross-correlation within ±5 ms window
        [ccf, lags] = xcorr(spikes1, spikes2, central_window);

        % Exclude zero lag
        non_zero_lag_indices = lags ~= 0;
        ccf_no_zero = ccf(non_zero_lag_indices);
        lags_no_zero = lags(non_zero_lag_indices);

        % Check if coincidence count meets threshold
        if sum(ccf_no_zero) < thr_spikes
            fprintf('[Worker %d] Not enough coincidences in group %d for pair %d.\n', wid, group, pair_num);
            continue;
        end

        % Generate null distribution
        random_lags = randsample([-max_lag:-central_window-1, central_window+1:max_lag], num_random_lags, true);
        null_distribution = arrayfun(@(lag) sum(circshift(spikes1, lag) .* spikes2), random_lags);

        % Calculate z-scores
        mean_null = mean(null_distribution);
        std_null = std(null_distribution);
        z_scores = (ccf_no_zero - mean_null) / std_null;

        % Identify extreme z-scores for positive and negative lags
        pos_lag_indices = lags_no_zero > 0;
        neg_lag_indices = lags_no_zero < 0;

        [~, max_pos_idx] = max(abs(z_scores(pos_lag_indices)));
        [~, max_neg_idx] = max(abs(z_scores(neg_lag_indices)));

        z_scores_pos = z_scores(pos_lag_indices);
        z_scores_neg = z_scores(neg_lag_indices);
        lags_pos = lags_no_zero(pos_lag_indices);
        lags_neg = lags_no_zero(neg_lag_indices);

        % Store results
        max_zscore_pos(pair(1), pair(2), group) = z_scores_pos(max_pos_idx);
        max_zscore_neg(pair(1), pair(2), group) = z_scores_neg(max_neg_idx);
        max_zscore_lag_pos(pair(1), pair(2), group) = lags_pos(max_pos_idx);
        max_zscore_lag_neg(pair(1), pair(2), group) = lags_neg(max_neg_idx);
    end
end

% Save results for this worker
fprintf('[Worker %d] Saving results...\n', wid);
results.opt = opt;
results.zscore_pos = max_zscore_pos;
results.zscore_neg = max_zscore_neg;
results.zscore_lag_pos = max_zscore_lag_pos;
results.zscore_lag_neg = max_zscore_lag_neg;

save(fullfile(opt.save_path, sprintf('results_%s_%d', opt.name, wid)), 'results', '-v7.3');
fprintf('[Worker %d] Results saved successfully.\n', wid);
end
