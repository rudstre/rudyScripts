function [legend_cell,ax,behavSummary] = plotBehavioralSummary(behavStates,height,ts1,ts2,ax,hrs)
if nargin < 6
    hrs = false;
end
if nargin < 5 || isempty(ax)
    ax = gca;
end
if nargin < 4 || isempty(ts2)
    ts2 = length(behavStates);
end
if nargin < 3 || isempty(ts1)
    ts1 = 1;
end
if nargin < 2
    height = 10;
end

cols = [0 0 0; distinguishable_colors(max(behavStates),[1 1 1; 0 0 0])];

behavSummary = getBehavioralSummary(behavStates,60);

if hrs, div = 3600; else, div = 1; end
behavSummary = behavSummary(ts1:ts2);

legend_cell = {};
for state = 0 : max(behavSummary)
    stateEpochs = (findEpochsFromBinary(behavSummary == state))/div;
    addBlankLineWithColor(ax,[cols(state+1,:) .15])
    legend_cell{end+1} = sprintf('State %d',state);
    for epoch = stateEpochs'
        rectangle(ax,'Position',[epoch(1) 0 diff(epoch) height],'EdgeColor',[1 1 1],'FaceColor',[cols(state+1,:) .15]);
    end
end