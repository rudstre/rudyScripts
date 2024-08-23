function raster = struct2raster(unitStruct)
    spiketimes = [];
    trials = [];
    for i = 1:length(unitStruct)
        clc
        fprintf('%2.0f%% complete',i/length(unitStruct)*100);
        spiketimes = [spiketimes; unitStruct(i).spikeTimesQual/3];
        trials = [trials; repmat(i,length(unitStruct(i).spikeTimesQual),1)];
    end
    raster = spikeRasterPlot(spiketimes,'TrialData',trials);
end