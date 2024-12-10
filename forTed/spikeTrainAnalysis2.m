if ~exist('CompiledSpikeTrain','var')
    uiload
end

pairs = nchoosek(1:length(CompiledSpikeTrain),2);

if ~exist('spikes_binned','var')
    spikes_binned = cellfun(@spikeTimesToBins,CompiledSpikeTrain,'UniformOutput',false);
end

% Parameters
binning = 8;                  % Weeks per group
ul = 10 * 60 * 1000 * binning;% Samples per bin
short_lag_window = 5;         % ±5 ms window around zero lag (excluding zero)
min_bin_count = 0;            % Minimum spike coincidences required in ±5 ms window
max_lag = 100;                % Maximum lag for cross-correlation
num_random_lags = 1000;        % Number of random lags for null distribution sampling
chunk_size = 100;             % Number of pairs per chunk (adjust based on available memory)
alpha = .05;                  % Significance level

% Initialize output arrays using linear indexing
num_pairs = length(pairs);
num_groups = 32 / binning;
max_zscore_pos = NaN(num_pairs, num_groups);
max_zscore_neg = NaN(num_pairs, num_groups);
max_zscore_lag_pos = NaN(num_pairs, num_groups);
max_zscore_lag_neg = NaN(num_pairs, num_groups);
is_significant_pos = false(num_pairs, num_groups);
is_significant_neg = false(num_pairs, num_groups);

% Process in chunks to reduce memory usage
updateProgress(-1)
for chunk_start = 1:chunk_size:num_pairs
    chunk_end = min(chunk_start + chunk_size - 1, num_pairs);
    chunk_pairs = pairs(chunk_start:chunk_end, :);
    num_chunk_pairs = length(chunk_pairs);

    % Initialize temporary storage for this chunk
    temp_max_zscore_pos = NaN(num_chunk_pairs, num_groups);
    temp_max_zscore_neg = NaN(num_chunk_pairs, num_groups);
    temp_max_zscore_lag_pos = NaN(num_chunk_pairs, num_groups);
    temp_max_zscore_lag_neg = NaN(num_chunk_pairs, num_groups);
    temp_is_significant_pos = false(num_chunk_pairs, num_groups);
    temp_is_significant_neg = false(num_chunk_pairs, num_groups);

    % Process each pair in this chunk in parallel
    for i = 1:num_chunk_pairs
        pairnum = chunk_start + i - 1;
        pair = chunk_pairs(i, :);

        % Retrieve binned spike trains for each neuron in the pair
        spikes1_full = spikes_binned{pair(1)};
        spikes2_full = spikes_binned{pair(2)};

        for group = 1:num_groups

            updateProgress(num_pairs,10)

            % Define indices for the current group
            idx_start = ul * (group - 1) + 1;
            idx_end = min([idx_start + ul - 1, length(spikes1_full), length(spikes2_full)]);

            % Skip if indices are invalid
            if idx_start > idx_end
                continue;
            end

            % Extract relevant spike segments for the current group
            spikes1 = spikes1_full(idx_start:idx_end);
            spikes2 = spikes2_full(idx_start:idx_end);

            % Compute cross-correlation within ±5 ms window
            [ccf, lags] = xcorr(spikes1, spikes2, short_lag_window);

            % Exclude zero lag
            non_zero_lag_indices = lags ~= 0;
            ccf_no_zero = ccf(non_zero_lag_indices); % Cross-correlation excluding zero lag
            lags_no_zero = lags(non_zero_lag_indices);

            % Check if coincidence count meets minimum threshold
            coincidence_count = sum(ccf_no_zero);
            if coincidence_count < min_bin_count
                continue; % Skip this pair for the current group if not enough coincidences
            end

            % Generate null distribution by randomly sampling cross-correlation at distant lags
            random_lags = randsample([-max_lag:-short_lag_window-1, short_lag_window+1:max_lag], ...
                num_random_lags, true);
            null_distribution = zeros(1, num_random_lags);

            for k = 1:num_random_lags
                shifted_spikes1 = circshift(spikes1, random_lags(k));
                null_distribution(k) = sum(shifted_spikes1 .* spikes2);
            end

            % Calculate z-scores for each lag in ±5 ms window (excluding zero lag)
            mean_null = mean(null_distribution);
            std_null = std(null_distribution);
            z_scores = (ccf_no_zero - mean_null) / std_null;

            % Identify the most abnormal z-score before and after zero lag
            pos_lag_indices = lags_no_zero > 0;
            neg_lag_indices = lags_no_zero < 0;

            % Find maximum absolute z-score and its index for positive and negative lags
            [max_abs_z_pos, max_pos_idx] = max(abs(z_scores(pos_lag_indices)));
            [max_abs_z_neg, max_neg_idx] = max(abs(z_scores(neg_lag_indices)));

            % Extract the actual z-score values (not absolute) for the most abnormal lags
            z_scores_pos = z_scores(pos_lag_indices);
            z_scores_neg = z_scores(neg_lag_indices);
            lags_pos = lags_no_zero(pos_lag_indices);
            lags_neg = lags_no_zero(neg_lag_indices);

            % Store the most abnormal z-score and its corresponding lag for positive and negative lags
            temp_max_zscore_pos(i, group) = z_scores_pos(max_pos_idx);
            temp_max_zscore_neg(i, group) = z_scores_neg(max_neg_idx);
            temp_max_zscore_lag_pos(i, group) = lags_pos(max_pos_idx);
            temp_max_zscore_lag_neg(i, group) = lags_neg(max_neg_idx);

            % Determine if each of these values is statistically significant
            significance_threshold = norminv(1 - alpha / 2); % Two-tailed test at 5% level
            temp_is_significant_pos(i, group) = abs(max_abs_z_pos) > significance_threshold;
            temp_is_significant_neg(i, group) = abs(max_abs_z_neg) > significance_threshold;
        end
    end

    % Store chunk results in the main arrays
    max_zscore_pos(chunk_start:chunk_end, :) = temp_max_zscore_pos;
    max_zscore_neg(chunk_start:chunk_end, :) = temp_max_zscore_neg;
    max_zscore_lag_pos(chunk_start:chunk_end, :) = temp_max_zscore_lag_pos;
    max_zscore_lag_neg(chunk_start:chunk_end, :) = temp_max_zscore_lag_neg;
    is_significant_pos(chunk_start:chunk_end, :) = temp_is_significant_pos;
    is_significant_neg(chunk_start:chunk_end, :) = temp_is_significant_neg;

    % Optionally, save intermediate results to reduce risk of data loss
    save('partial_results.mat', 'max_zscore_pos', 'max_zscore_neg', ...
        'max_zscore_lag_pos', 'max_zscore_lag_neg', 'is_significant_pos', 'is_significant_neg');
end

% Final save to ensure all results are stored
save('results.mat', 'max_zscore_pos', 'max_zscore_neg', ...
    'max_zscore_lag_pos', 'max_zscore_lag_neg', 'is_significant_pos', 'is_significant_neg');

% Function to update progress and display ETA
function updateProgress(total_iterations,every)

persistent num_completed last_update elapsed_time

if total_iterations == -1 || isempty(num_completed)
    num_completed = 0; 
    last_update = tic; 
    elapsed_time = 0;
    return
end

num_completed = num_completed + 1;
elapsed_time = elapsed_time + toc(last_update); % Time since last update
avg_time_per_iteration = elapsed_time / num_completed;
remaining_time = avg_time_per_iteration * (total_iterations - num_completed);

% Display progress
if nargin < 2
    every = 20;
end
if mod(num_completed, every) == 1
    clc
    fprintf('Progress: %2.1f%%, Estimated Time Remaining: %.1f minutes\n', ...
        (num_completed / total_iterations) * 100, remaining_time / 60);
end
last_update = tic; % Reset last update timer
end