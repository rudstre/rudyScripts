if ~exist('CompiledSpikeTrain','var')
    uiload
end

pairs = nchoosek(1:length(CompiledSpikeTrain),2);

if ~exist('spikes_binned','var')
    spikes_binned = cellfun(@spikeTimesToBins,CompiledSpikeTrain,'UniformOutput',false);
end

% Convolve with spike train
z_crit = 3;

% Init variables
elapsed = 1;
sig = zeros(length(pairs),1);
[corrs, lags] = deal({}); [max_idx, dir] = deal([]);

binning = 8; % weeks

ll = 0;
ul = 600000 * binning;

% Compute xcorr for each pair
for pairnum = 1:length(pairs)

    pair = pairs(pairnum,:);
    % Calculate time remaining
    tic
    w = (1 : length(elapsed)).^2; w = w / sum(w);
    mn_elapsed = sum(elapsed .* w);
    t_remain = mn_elapsed * (length(pairs) - pairnum)/60;
    if mod(pairnum,20) == 0
        clc
        fprintf('%2.1f%% done.. \nETA: %.1f minutes\n', ...
            pairnum/length(pairs)*100, t_remain);
    end

    % Compute cross-correlation
    all_spikes_1 = spikes_binned{pair(1)};
    all_spikes_2 = spikes_binned{pair(2)};

    for group = 1 : (32/binning)
        idx_start = ul * (group-1) + 1;
        idx_end = min([(idx_start + ul - 1),size(all_spikes_1,2),size(all_spikes_2,2)]);
        spikes1 = all_spikes_1(idx_start:idx_end);
        spikes2 = all_spikes_2(idx_start:idx_end);
        if idx_start > idx_end
            if size(all_spikes_1,2) < idx_start
                fr(pair(1),group) = nan;
            elseif size(all_spikes_2,2) < idx_start
                fr(pair(2),group) = nan;
            end
            continue
        end
        fr(pair(1),group) = (sum(spikes1)/(idx_end - idx_start)) * 1000;
        fr(pair(2),group) = (sum(spikes2)/(idx_end - idx_start)) * 1000;
        if any([fr(pair(1),group) fr(pair(2),group)] < .1)
            interaction{pairnum,group} = nan;
            continue
        end
        [amp,lag] = xcorr(spikes1,spikes2, 100);

        % Calculate meaningful threshold
        baseline = [1:40 60:101];
        mn = mean(amp(baseline));
        st = std(amp(baseline));
        thr = mn + st * z_crit * [-1 1];
        amp(lag == 0) = nan;

        % Compute whether xcorr around zero is meaningful
        dist = distFromRange(amp(iswithin(lag, -4, 4)), thr);
        idx_0 = ceil(length(dist)/2);
        if any(dist) && any(abs(thr) > 1)
            [~,i_neg] = max(abs(dist(1:idx_0 - 1)));
            [~,i_pos] = max(abs(dist(idx_0+1:end))); i_pos = i_pos + idx_0;
            interaction{pairnum,group} = [dist(i_neg) dist(i_pos)];
        end
    end

    % Compute time spent
    elapsed(end+1) = toc;
end