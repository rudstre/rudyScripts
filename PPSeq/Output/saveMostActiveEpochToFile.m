function output = saveMostActiveEpochToFile(data,session,t_max,silent)

    if nargin < 4
        silent = false;
    end

    if ~silent
        path = uigetdir('Select save location:');
    end

    sessionData = data(session);

    h = histogram(sessionData.leverOnTimes,'BinWidth',1000);
    activity = movsum(h.Values,t_max,'Endpoints','fill');
    [~,i] = max(activity);
    t_center = h.BinEdges(i) + h.BinWidth/2;
    t_start = t_center - t_max*1000/2;
    t_end = t_center + t_max*1000/2;
    close all

    spikeVec = [];
    cnt = 0;
    for i = 1:length(sessionData.spikeTimes)
        spikes = sessionData.spikeTimes{i};
        valid = iswithin(spikes,t_start,t_end);
        isi{i} = diff(spikes(valid));
        ff(i) = var(isi{i})/(mean(isi{i})^2);
        if ~iswithin(ff(i),.5,20) || length(spikes(valid))/t_max < .25
            if ~silent
                fprintf('Unit %d ignored.\n',i)
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
    output(:,2) = round(output(:,2) - t_start)/1000;
    output(:,2) = output(:,2) + .01;

    if ~silent
        fname = sprintf('spikes_session%s_start%d_end%d.txt',sessionData.sessionID,t_start,t_end);
        fp = fullfile(path,fname);
        writematrix(output,fp,'Delimiter','tab')
        fprintf(['\nSaved most active %d seconds of data from session %d to file. \n\n'...
            'Session ID: %s \nStart timestamp: %d \nEnd timestamp: %d \nAverage background rate: %.1f\nNumber of units: %d\n'],...
            t_max,session,sessionData.sessionID, t_start,t_end,length(output)/output(end,2),cnt)
    end
end