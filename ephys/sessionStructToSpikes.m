function [spikeMat,isi] = sessionStructToSpikes(activity,params,space)

    trials = size(activity(1).spikeTimes,2);
    trialLength = (params.postTimeWin-params.preTimeWin)*1000;
    spikeMat = zeros([length(activity),uint64(trials*trialLength)]);
    isi = {};
    for i = 1:length(activity)
        isi{i} = [];
        unit = activity(i);
        spikeTimes = unit.spikeTimes;
        for j = 1:trials
            trial_spikes = spikeTimes{j};
            t_c = trial_spikes(~isnan(trial_spikes)) - params.preTimeWin;
            if isempty(t_c)
                continue
            end
            spikeMat(i,round(t_c*1000)+(1+space)*(j-1)*trialLength) = 1;
            isi{i} = [isi{i}; diff(t_c*1000)];
        end      
    end
end