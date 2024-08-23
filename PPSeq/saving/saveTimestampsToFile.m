function [output,times,units_ignored] = saveTimestampsToFile(data,session,times,offset,ign_list,t_max,silent)
    if nargin < 6
        t_max = (times(2) - times(1))/1000;
    end

    if nargin < 7
        silent = false;
    end

    if nargin < 5
        ign_list = -1;
    end

    if nargin < 4
        offset = 0;
    end

    sessionData = data(session);
    unitLabels = sessionData.unitLabel;

    spikeVec = [];
    units_ignored = [];
    cnt = 0;

    for i = 1:length(sessionData.spikeTimes)
        currUnit = unitLabels(i);
        spikes = sessionData.spikeTimes{i};
        valid = iswithin(spikes,times);
        isi{i} = diff(spikes(valid));
        ff(i) = var(isi{i})/(mean(isi{i})^2);
        if any(ign_list == currUnit) || ...
                (all(ign_list == -1) && (~iswithin(ff(i),.5,12) || length(spikes(valid))/t_max < .25))
            if ~silent
                fprintf('Unit %d ignored.\n',currUnit)
                units_ignored = [units_ignored currUnit];
            end
            continue
        end
        cnt = cnt + 1;
        newSpikes = [cnt*ones([nnz(valid),1]) spikes(valid)];
        spikeVec = [spikeVec; newSpikes];
    end

    if isempty(spikeVec)
        output = [0 0];
        return
    end
    output = spikeVec;
    output(:,2) = round(output(:,2) - times(1))/1000;
    output(:,2) = output(:,2) + .01 + offset;

    if ~silent
        fpath = uigetdir('Select save location:');
        fname = sprintf('spikes_session%s_start%d_end%d.txt',sessionData.sessionID,times(1),times(2));
        fp = fullfile(fpath,fname);
        writematrix(output,fp,'Delimiter','tab')
        fprintf(['\nSaved most active %d seconds of data from session %d to file. \n\n'...
            'Session ID: %s \nStart timestamp: %d \nEnd timestamp: %d \nAverage background rate: %.1f\nNumber of units: %d\n'],...
            t_max,session,sessionData.sessionID, times(1),times(2),length(output)/t_max,cnt)
    end
end

