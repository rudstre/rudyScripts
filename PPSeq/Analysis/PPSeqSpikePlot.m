function [ord,PPSeq,leverData] = PPSeqSpikePlot(ord,data,leverOffset,spikeOffset)

if nargin < 4
    spikeOffset = 0;
end

if nargin < 3
    leverOffset = 0;
end

if nargin < 2
    plotLever = false;
else
    plotLever = true;
end

if nargin < 1
    ord = [];
end

[PPSeq,spike_info] = importPPSeqModel;

% plotLever = true;
gcfFullScreen;

if plotLever
    [ax_lever,legend_lever,leverData] = plotLeverPresses(data,spike_info,leverOffset,1000);

    % Hack to be able to get two legends on the same figure
    ax_seq = copyobj(ax_lever, gcf); delete(get(ax_seq, 'Children'));
    set(ax_seq,'visible','off')
    linkaxes([ax_lever,ax_seq])
else
    ax_seq = gca;
end

[~,idx] = ismember(PPSeq.assignments,PPSeq.events.assignment_id);

spikes = PPSeq.spikes; spikes(:,2) = spikes(:,2) - spikeOffset;

spikes(:,3) = PPSeq.events.type(idx);

% spikes(:,4) = PPSeq.events.warp(idx);

%% Reorder
seqtypes = unique(spikes(:,3));
seq_oi = [3,1];

skip = [];
evnts = PPSeq.events;

if isempty(seq_oi)
    spikes(:,1) = PPSeq.order(spikes(:,1));
elseif ~isempty(ord)
    skip = seqtypes; skip(ismember(skip,seq_oi)) = [];
    spikes(:,1) = arrayfun(@(x) find(ord == x),spikes(:,1));
else
    skip = seqtypes; skip(ismember(skip,seq_oi)) = [];

    amps_oi = evnts.amplitudes(:,seq_oi);
    [~,n] = max(amps_oi,[],2);

    n(all(amps_oi < -4,2)) = 0;

    ord = [];
    for i = 1:length(seq_oi)
        cur_seq = seq_oi(i);
        cur_units = find(n == i);
        offsets_oi = evnts.offsets(cur_units,cur_seq);
        [~,idx] = sort(offsets_oi);
        ord = [ord; cur_units(idx)];
    end
    ord = [ord; find(~ismember(1:33,ord))'];
    spikes(:,1) = arrayfun(@(x) find(ord == x),spikes(:,1));
end

%% Colors
col_mat = [0,0,0; ...
    distinguishable_colors(11, {'w','k'})...
    ];

% col_mat = col_mat([1,3,5,9,10,11],:);

%%

for i = 1:length(seqtypes)
    seq = seqtypes(i);
    spikesOI = spikes(:,3) == seq;
    seq_spikes = spikes(spikesOI,1:2);
    hold on
    if ismember(seq,skip)
        scatter(ax_seq,seq_spikes(:,2), seq_spikes(:,1), 18, [.85,.85,.85], 'filled')
        continue
    end

    if isempty(seq_spikes)
        scatter(ax_seq,nan, nan, 18, col_mat(i,:), 'filled')
        continue
    end
    scatter(ax_seq,seq_spikes(:,2), seq_spikes(:,1), 18, col_mat(i,:), 'filled')
end


%% Legend stuff
legend_seq = {'background spikes'};

for i = 2:length(seqtypes)
    seq = seqtypes(i);
    legend_seq{end+1} = sprintf('sequence %d',seq);
end

legend(ax_seq,legend_seq,'Location', 'northeast')
set(ax_seq,'FontSize',18)

if plotLever
    legend(ax_lever,legend_lever,'Location', 'southeast')
    set(ax_lever,'FontSize',18)
end

xlim([0 30])
ylim([0 max(spikes(:,1))])

%% Plot event timestamps and warp
% eventsOI = iswithin(evnts.type, 8, 8);
% 
% scatter(evnts.ts(eventsOI), ...
%     -1 * evnts.type(eventsOI), ...
%     1 * 100)