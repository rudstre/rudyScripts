function saveSessionToFile(data,session,t_max)

    %% Get save location
    [file,path] = uiputfile('*.txt','Select save location:');
    fp = fullfile(path,file);

    %% Compute spike matrix from struct
    activity = data.units(session).activity;
    unitIDs = {activity.unitID};
    trialLength = (data.params.postTimeWin-data.params.preTimeWin)*1000;
    [spikeMat,isi] = sessionStructToSpikes(activity,data.params,space);

    %% Filter by neuron fano factor
    ff = cellfun(@(x) var(x)/mean(x)^2,isi);
    valid = iswithin(ff,.5,12);
    numTrials = ceil(time2trial(t_max,trialLength,space));
    t_end = trial2time(numTrials,trialLength,space);
    spikeMat = spikeMat(valid,1:t_end);
    
    %% Print out summary
    fprintf(['First %d trials saved from session %d. \n'...
        'Actual total time: %.3f seconds\n'...
        'λ = %.0f\n'...
        'Neuron count: %d\n'],...
        numTrials,session,t_end/1000,nnz(spikeMat)*1000*.3/size(spikeMat,2),nnz(valid));

    %% Convert to output text file
    [unit,ts] = find(spikeMat);

    % validIDs = cellfun(@(x) str2double(x(3:end)), unitIDs(valid))';

    output = [unit ts/1000];
    writematrix(output,fp,'Delimiter','tab')
end

function numTrials = time2trial(t_max,trialLength,space)
    numTrials = (t_max*1000/trialLength + space)/(1 + space);
end

function t_end = trial2time(numTrials,trialLength,space)
    t_end = trialLength*((1 + space) * numTrials - space);
end
