function PPSeqSpikePlot(data,sessions,times,leverOffset,spikeOffset)

    gcfFullScreen;
    ax_lever = plotLeverPresses(data,sessions,times,leverOffset);
    
    ax_seq = copyobj(ax_lever, gcf); delete(get(ax_seq, 'Children'));
    set(ax_seq,'visible','off')
    linkaxes([ax_lever,ax_seq])

    importPPSeqModel;

    [~,idx] = ismember(PPSeq.assignments,PPSeq.events.assignment_id);

    spikes = PPSeq.spikes; spikes(:,2) = spikes(:,2) - spikeOffset;

    spikes(:,3) = PPSeq.events.type(idx);

    spikes(:,1) = PPSeq.order(spikes(:,1));
    seqtypes = [-1 1:11];%unique(spikes(:,3));

    col_mat = [0,0,0;distinguishable_colors(length(seqtypes),{'w','k'})];
    skip = [3,9,11];
    
    for i = 1:length(seqtypes)
        seq = seqtypes(i);
        seq_spikes = spikes(spikes(:,3) == seq,1:2);
        if ismember(seq,skip)
            continue
        end
        
        if isempty(seq_spikes)
            scatter(ax_seq,nan,nan,18,col_mat(i,:),'filled')
            continue
        end

        scatter(ax_seq,seq_spikes(:,2),seq_spikes(:,1),18,col_mat(i,:),'filled')
        hold on
    end


    legend_lever = {'center lever','left lever','right lever'};
    legend_seq = {'background spikes'};

    for i = 2:length(seqtypes)
        seq = seqtypes(i);
        if ismember(seq,skip)
            continue
        end
        legend_seq{end+1} = sprintf('sequence %d',seq);
    end

    legend(ax_lever,legend_lever,'Location', 'southeast')
    legend(ax_seq,legend_seq,'Location', 'northeast')


    xlim([0 30])
    ylim([0 max(spikes(:,1))])
    set(ax_lever,'FontSize',18)
    set(ax_seq,'FontSize',18)
