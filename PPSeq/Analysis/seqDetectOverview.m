function seqDetectOverview(PPSeq, seqs, behavStates, amp_thresh, f_len)

%% Plot overview
if nargin < 3 || isempty(behavStates)
    plotStates = false;
else
    plotStates = true;
end
if nargin < 5
    f_len = 60;
end
if nargin < 4
    amp_thresh = 15;
end
if nargin < 2
    seqs = unique(PPSeq.events.type)';
end

legend_cell = {};
for seq = seqs
    if seq == -1
        continue
    end
    hold on
    [n,e] = histcounts(PPSeq.events.ts(PPSeq.events.type == seq & PPSeq.events.event_amp > amp_thresh),'BinWidth',1);
    sm = movsum(n,f_len,'Endpoints','fill');
    plot(e(1:end-1)/60/60,sm/f_len,'LineWidth',2)
    legend_cell{end+1} = sprintf('Sequence %d',seq);
end
axis tight
set(gca,'FontSize',18)
xlim([0,5])
xlabel('time (h)')
ylabel('seq/sec')
ax = gca;
yl = ax.YLim;

if plotStates
    stateLegend = plotBehavioralSummary(behavStates,max(yl)+1,[],[],[],true);
end

legend([legend_cell stateLegend])
ylim(yl);