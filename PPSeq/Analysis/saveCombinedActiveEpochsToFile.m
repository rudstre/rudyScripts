function [output,times,units_ignored] = ...
        saveCombinedActiveEpochsToFile(data,sessions,t_max,silent,ign_list)

    if nargin < 5
        ign_list = -1;
    end

    if nargin < 4
        silent = false;
    end

    if ~silent
        [fname,path] = uiputfile('*.txt','Select save location',...
            '/Users/rudygelb-bicknell/Documents/PPSeq_fork.jl/demo/data/');
    end

    sessionData = data(sessions);
    t_max_i = round(t_max/length(sessions));

    unitLabels = data(sessions(1)).unitLabel;
    for s = 2:length(sessions)
        unitLabels = intersect(unitLabels,data(sessions(s)).unitLabel);
    end

    for i = 1:length(sessionData)
        h = histogram(sessionData(i).leverOnTimes,'BinWidth',1000);
        activity = movsum(h.Values,t_max_i,'Endpoints','fill');
        [~,idx] = max(activity);
        t_center = h.BinEdges(idx) + h.BinWidth/2;
        times(i,1) = t_center - t_max_i*1000/2;
        times(i,2) = t_center + t_max_i*1000/2;
        close all
    end

    spikeVec = [];
    units_ignored = [];
    invalid = [];
    cnt = 0;

    for i = 1:length(unitLabels)
        currUnit = unitLabels(i);
        valid = [];
        spikes = [];
        for j = 1:length(sessionData)
            idx = sessionData(j).unitLabel == currUnit;
            spikes_new = sessionData(j).spikeTimes{idx} - times(j,1);
            valid_new = iswithin(spikes_new,0,t_max_i*1000);
            isi{i,j} = diff(spikes_new(valid_new));
            ff(i,j) = var(isi{i,j})/(mean(isi{i,j})^2);
            valid = logical([valid; valid_new]);
            spikes_new = spikes_new + t_max_i*(j-1)*1000;
            fr(i,j) = length(spikes_new(valid_new))/(t_max_i);
            spikes = [spikes; spikes_new];
        end
        if any(ign_list == currUnit) || ...
                (all(ign_list == -1) && (~any(iswithin(ff(i,:),.5,12)) || all(fr(i,:) < .25) || any(fr(i,:) > 5)))
            if ~silent
                fprintf('Unit %d ignored.\n',currUnit)
                units_ignored = [units_ignored currUnit];
                invalid = [invalid i];
            end
            continue
        end
        cnt = cnt + 1;
        newSpikes = [cnt*ones([nnz(valid),1]), spikes(valid)];
        spikeVec = [spikeVec; newSpikes];
    end

    if isempty(spikeVec)
        output = [0 0];
        return
    end
    output = spikeVec;
    output(:,2) = round(output(:,2))/1000;
    output(:,2) = output(:,2) + .01;

    if ~silent
        fp = fullfile(path,fname);
        writematrix(output,fp,'Delimiter','tab')
        fprintf(['\nSaved most active %d seconds of data from sessions %s to ''%s''. \n\n'...
            '\nAverage background rate: %.1f\nNumber of units: %d\nNumber of total spikes: %d\n'],...
            t_max,num2str(sessions), fp, length(output)/output(end,2),cnt,length(output))
    end
end