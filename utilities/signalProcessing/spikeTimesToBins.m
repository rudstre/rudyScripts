function spikes_t = spikeTimesToBins(spikes,binsize)
if nargin < 2
    binsize = .001; % 1ms
end
if isempty(spikes)
    spikes_t = [];
    return
end

spikes_bz = spikes / binsize;

spikes_t = histcounts(spikes_bz,0 : ceil(max(spikes_bz)));
end