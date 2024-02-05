function units = getNumGoodUnits(data,timeframe)
    if nargin < 2
        timeframe = 600;
    end
    for i = 1:length(data)
        spikes = saveMostActiveEpochToFile(data,i,timeframe,true);
        units(i) = max(spikes(:,1));
    end
end