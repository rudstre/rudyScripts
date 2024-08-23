function [output,times,units_ignored] = ...
    saveCombinedActiveEpochsToFile(data,sessions,t_max,silent,ign_list,removeDup)

if nargin < 6
    removeDup = true;
end

if nargin < 5 || isempty(ign_list)
    ign_list = -1;
end

if nargin < 4
    silent = false;
end

if ~silent
    [fname,path] = uiputfile('*.txt','Select save location',...
        '/Users/rudygelb-bicknell/Documents/PPSeq_fork.jl/demo/data/');
end

fs_lever = 1000;
fs_spikes = 1000;

sessionData = data(sessions);
t_max_i = round(t_max/length(sessions));


%% Get valid unit subset
unitLabels = data(sessions(1)).unitLabel;
for s = 2:length(sessions)
    unitLabels = intersect(unitLabels,data(sessions(s)).unitLabel);
end


%% Get most active epoch
for i = 1:length(sessionData)
    h = histogram(sessionData(i).leverOnTimes,'BinWidth',fs_lever);
    activity = movsum(h.Values,t_max_i,'Endpoints','fill');
    [~,idx] = max(activity);
    t_center = h.BinEdges(idx) + h.BinWidth/2;
    times(i,1) = t_center/fs_lever - t_max_i/2;
    times(i,2) = t_center/fs_lever + t_max_i/2;
    close all
end


%% Get spikes for each valid unit during epoch
spikeVec = [];
units_ignored = [];
indices_ignored = [];
cnt = 0;
units = [];
for i = 1:length(unitLabels)
    currUnit = unitLabels(i);
    valid = [];
    spikes = [];
    for j = 1:length(sessionData)
        idx = sessionData(j).unitLabel == currUnit;
        spikes_new = double(sessionData(j).spikeTimes{idx})/fs_spikes - times(j,1);
        valid_new = iswithin(spikes_new,0,t_max_i);
        isi{i,j} = diff(spikes_new(valid_new));
        ff(i,j) = var(isi{i,j})/(mean(isi{i,j})^2);
        valid = logical([valid; valid_new]);
        spikes_new = spikes_new + t_max_i*(j-1);
        fr(i,j) = length(spikes_new(valid_new))/t_max_i;
        spikes = [spikes; spikes_new];
    end
    if any(ign_list == currUnit) || ...
            (all(ign_list == -1) && (~any(iswithin(ff(i,:),.5,12)) || all(fr(i,:) < .25) || any(fr(i,:) > 5)))
        if ~silent
            fprintf('Unit %d ignored.\n',currUnit)
            units_ignored = [units_ignored currUnit];
            indices_ignored = [indices_ignored i];
        end
        continue
    end
    cnt = cnt + 1;
    units(end+1) = currUnit;
    newSpikes = [cnt*ones([nnz(valid),1]), spikes(valid)];
    spikeVec = [spikeVec; newSpikes];
end


%% Create output
if isempty(spikeVec)
    output = [0 0];
    return
end

output = spikeVec;
output(:,2) = round(output(:,2),3) + .001;

%% Check for duplicate units (Komolgrov-Smirnov test)

unitsToDelete = [];
if removeDup
    % Run test on every pair of units
    pairs = nchoosek(unique(output(:,1)),2);
    for i = 1:size(pairs,1)
        [~,p(i)] = kstest2( ...
            output(output(:,1) == pairs(i,1), 2),...
            output(output(:,1) == pairs(i,2), 2));
    end

    % Figure out which units to delete
    duplUnits = pairs(p > .95,:);
    unitsToDelete = duplUnits(:,2); % delete the second unit

    % Delete unit
    output(ismember(output(:,1),unitsToDelete),:) = [];
    units_ignored = [units_ignored units(unitsToDelete)];
    indices_ignored = [indices_ignored unitsToDelete];
    units(unitsToDelete) = [];
    cnt = cnt - length(unitsToDelete);

    % Shift indices to accomodate for deleted units
    ord_new = unique(output(:,1));
    output(:,1) = arrayfun(@(x) find(ord_new == x),output(:,1));
end

%% Save results and info
if ~silent
    fp = fullfile(path,fname);
    writematrix(output,fp,'Delimiter','tab')
    fprintf(['\nSaved most active %d seconds of data from sessions %s to ''%s''. \n\n'...
        'Number of duplicate units removed: %d\n'...
        '\nAverage background rate: %.1f\nNumber of units: %d\nNumber of total spikes: %d\n'],...
        t_max, num2str(sessions), fp, ...
        length(unitsToDelete), ...
        length(output) / output(end,2), cnt, length(output))

    [~,fname_noext] = fileparts(fp);

    spike_info.times = seconds(times) + datetime([sessionData.sessionStartTime],'ConvertFrom','posix')';
    spike_info.units = units;
    spike_info.units_ignored = units_ignored;
    spike_info.indices_ignored = indices_ignored;
    spike_info.ignore_list = ign_list;
    spike_info.total_units = cnt;
    spike_info.total_spikes = length(output);
    spike_info.total_time = t_max;
    spike_info.chain_ephys = unique({sessionData.chainEphysFile});
    save(fullfile(path,[fname_noext '_info']),'spike_info');
end
end