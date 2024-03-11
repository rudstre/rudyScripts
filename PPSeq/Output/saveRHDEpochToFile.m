function end_time = saveRHDEpochToFile(ustruct,rhdID,t_start,t_end,offset,fp)

validSessions = cellfun(@(x)any(strcmp(rhdID,x)),{ustruct.chainEPhysFile});

unitLabels = find(validSessions);
sessionUnits = ustruct(unitLabels);

labels = cellfun(@(x) find(strcmp(rhdID, x)),...
    {sessionUnits.chainEPhysFile}, 'UniformOutput', false);

for i = 1:length(unitLabels)
    sessionUnits(i).unitLabels = unitLabels(i);
end

for i = 1:length(sessionUnits)
    unit = sessionUnits(i);
    sessionUnits(i).spikeTimes = unit.spikeTimes(...
        ismember(unit.spikeLabels,labels{i}) & iswithin(unit.spikeTimes,t_start,t_end))';
end

unitLabels_all = repelem(unitLabels, ...
    cellfun(@length,{sessionUnits.spikeTimes}));

spikeVec = double([ unitLabels_all' [sessionUnits.spikeTimes]' ]);

output = spikeVec; 
output(:,2) = (output(:,2) - min(output(:,2)))/30000 + .01 + offset;
output(:,2) = round(output(:,2),3);

end_time = max(output(:,2));

if nargin < 6
    [fname,path] = uiputfile('*.txt','Select save location',...
        '/Users/rudygelb-bicknell/Documents/PPSeq_fork.jl/demo/data/');
    fp = fullfile(path,fname);
end

if exist(fp,'file')
    writematrix(output,fp,'Delimiter','tab','WriteMode','append')
else
    writematrix(output,fp,'Delimiter','tab')
end