function [spikes_t,t_start] = spikeTimesToBins(spikes,binsize)
if nargin < 2
    binsize = .001; % upscale time by 1000x (sec to ms)
end
if isempty(spikes)
    spikes_t = [];
    t_start = nan;
    return
end

minCell = cellfun(@min,spikes,'UniformOutput',false);
maxCell = cellfun(@max,spikes,'UniformOutput',false);

t_start = min([minCell{:}]) / binsize;
t_end = max([maxCell{:}]) / binsize;

spikes_t = cellfun(@(s) histcounts(s / binsize, t_start : t_end), spikes, 'UniformOutput', false);
end