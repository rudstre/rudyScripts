function spikeTrainCorrelation(opt, wid, w_tot)
    % Spike train cross-correlation analysis with z-score calculation
    % Args:
    %   opt: Options structure containing analysis parameters and paths
    %   wid: Worker ID for parallel processing
    %   w_tot: Total number of workers

    % Unpack options
    opt = opt.opt;
    pairs = opt.pairs;
    binning = opt.binning;
    central_window = opt.central_window;
    thr_spikes = opt.thr_spikes;
    max_lag = opt.max_lag;
    num_random_lags = opt.num_random_lags;

    % Generate groups of pairs based on worker ID
    groups = generatePairGroups(max(pairs(:)), w_tot); 
    group = groups{wid};
    pairs = pairs(ismember(pairs(:, 1), group), :);

    % Binned recording length (in samples)
    ul = opt.timePerRec * 1000 * binning;

    % Initialize output arrays using NaN to handle absent data
    num_cells = max(pairs(:));
    num_groups = 32 / binning;
    max_zscore_pos = NaN(num_cells, num_cells, num_groups);
    max_zscore_neg = NaN(num_cells, num_cells, num_groups);
    max_zscore_lag_pos = NaN(num_cells, num_cells, num_groups);
    max_zscore_lag_neg = NaN(num_cells, num_cells, num_groups);

    % Load spikes and filter for unique units
    unique_units = unique(pairs(:));
    spikes = load(opt.spike_path).spikes;
    spikes = spikes(unique_units);
    pairs_converted = arrayfun(@(x) find(unique_units == x, 1), pairs);

    % Iterate over pairs of neurons
    for pair_num = 1:length(pairs)
        fprintf('[Worker %d of %d] Progress: Pair %d of %d\n', wid, w_tot, pair_num, length(pairs));
        pair = pairs_converted(pair_num, :);

        % Retrieve full spike trains for the neuron pair
        spikes1_full = spikes{pair(1)};
        spikes2_full = spikes{pair(2)};

        % Process data in groups (e.g., time bins)
        for group = 1:num_groups
            % Define segment indices for the current group
            idx_start = ul * (group - 1) + 1;
            idx_end = min([idx_start + ul - 1, length(spikes1_full), length(spikes2_full)]);

            % Skip invalid segments
            if idx_start > idx_end
                continue;
            end

            % Extract spike segments for the current group
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
    results.opt = opt;
    results.zscore_pos = max_zscore_pos;
    results.zscore_neg = max_zscore_neg;
    results.zscore_lag_pos = max_zscore_lag_pos;
    results.zscore_lag_neg = max_zscore_lag_neg;

    save(fullfile(opt.save_path, sprintf('results_%s_%d', opt.name, wid)), 'results', '-v7.3');
end
