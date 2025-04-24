function [spikes_t, ts, resolution] = spikeTimesToBins(spikes, resolution)
if nargin < 2
    resolution = milliseconds(1); % Default: 1 ms bins
end

% Handle empty input
if isempty(spikes)
    spikes_t = {};
    ts = [];
    return
end

% Filter out empty cells for min/max calculations
nonEmptySpikes = spikes(~cellfun(@isempty, spikes));
if isempty(nonEmptySpikes)
    spikes_t = cellfun(@(x) [], spikes, 'UniformOutput', false);
    ts = [];
    return
end

% Convert resolution to seconds
resolution_s = seconds(resolution);

% Determine global min and max spike time
minTime = min(cellfun(@min, nonEmptySpikes));
maxTime = max(cellfun(@max, nonEmptySpikes));

% Convert to time in bin units
t_start = floor(minTime / resolution_s);
t_end   = ceil(maxTime / resolution_s);

% Create bin edges in bin index units
edges = t_start : t_end + 1;  % +1 ensures we capture the last bin

% Compute histograms for each spike train (handle empty spike vectors)
spikes_t = cellfun(@(s) histcounts(s / resolution_s, edges), spikes, 'UniformOutput', false);

% Time vector (bin centers)
bin_centers = (edges(1:end-1) + 0.5);  % midpoints of bins
ts = bin_centers * resolution;        % convert back to duration
end