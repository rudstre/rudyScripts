function [spikes_t,ts,resolution] = spikeTimesToBins(spikes,resolution)
if nargin < 2
    resolution = milliseconds(1); % ms resolution by default
end
if isempty(spikes)
    spikes_t = [];
    ts = [];
    return
end

minCell = cellfun(@min,spikes,'UniformOutput',false);
maxCell = cellfun(@max,spikes,'UniformOutput',false);

resolution_s = seconds(resolution);
t_start = min([minCell{:}]) / resolution_s;
t_end = max([maxCell{:}]) / resolution_s;

[spikes_t,ts_cell] = cellfun(@(s) histcounts(s / resolution_s, t_start : t_end), spikes, 'UniformOutput', false);
ts = ts_cell{1} * milliseconds(resolution);
end