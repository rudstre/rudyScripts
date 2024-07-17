function end_time = saveRHDEpochToFile(ustruct,rhdID,start_time,t_len,fs,offset,fp,unit_list,overwrite)

if nargin < 9
    overwrite = true;
end

[t_start, rhdID] = getOffsetFromRHDStart(start_time,rhdID);
t_end = t_start + t_len;

t_start_s = seconds(t_start) * fs;
t_end_s = seconds(t_end) * fs;

validSessions = cellfun(@(x)any(strcmp(rhdID,x)),{ustruct.chainEPhysFile});

unitLabels = find(validSessions);
labIdx = arrayfun(@(x) find(unitLabels == x),unit_list);
unitLabels = unitLabels(labIdx);

sessionUnits = ustruct(unitLabels);

labels = cellfun(@(x) find(strcmp(rhdID, x)),...
    {sessionUnits.chainEPhysFile}, 'UniformOutput', false);

for i = 1:length(unitLabels)
    sessionUnits(i).unitLabels = unitLabels(i);
end

for i = 1:length(sessionUnits)
    unit = sessionUnits(i);
    sessionUnits(i).spikeTimes = unit.spikeTimes(...
        ismember(unit.spikeLabels,labels{i}) & iswithin(unit.spikeTimes,t_start_s,t_end_s))';
end

unitLabels_all = repelem(1:length(unitLabels), ...
    cellfun(@length,{sessionUnits.spikeTimes}));

spikeVec = double([ unitLabels_all' [sessionUnits.spikeTimes]' ]);

output = spikeVec; 
output(:,2) = output(:,2)/fs - seconds(t_start) + offset;
output(:,2) = round(output(:,2),3);

end_time = max(output(:,2));

if nargin < 7 || isempty(fp)
    [fname,path] = uiputfile('*.txt','Select save location',...
        '/Users/rudygelb-bicknell/Documents/PPSeq_fork.jl/demo/data/');
    fp = fullfile(path,fname);
end

if ~overwrite
    writematrix(output,fp,'Delimiter','tab','WriteMode','append')
else
    writematrix(output,fp,'Delimiter','tab')
end