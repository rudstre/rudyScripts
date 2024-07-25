function seqDetectOverview(PPSeq, seqs, behavStates, amp_thresh, f_len)
    % Plot an overview of sequence detections with optional behavioral states overlay
    %
    % Inputs:
    %   PPSeq: Structure containing event information, including types and timestamps
    %   seqs: Array of sequence types to plot (optional, default = unique sequences in PPSeq)
    %   behavStates: Vector of behavioral states (optional, default = no states plotted)
    %   amp_thresh: Amplitude threshold for filtering events (optional, default = 15)
    %   f_len: Filter length for smoothing the event count (optional, default = 60)
    
    %% Plot overview initialization
    % Determine if behavioral states are provided
    if nargin < 3 || isempty(behavStates)
        plotStates = false;
    else
        plotStates = true;
    end
    
    % Set default values for optional arguments
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
    hold on;
    
    % Plot each sequence type
    for seq = seqs
        if seq == -1
            continue; % Skip invalid sequence type
        end
        % Histogram of event timestamps for the current sequence
        [n, e] = histcounts(PPSeq.events.ts(PPSeq.events.type == seq & PPSeq.events.event_amp > amp_thresh), 'BinWidth', 1);
        
        % Smooth the histogram using a moving sum
        sm = movsum(n, f_len, 'Endpoints', 'fill');
        
        % Plot the smoothed sequence detections per hour
        plot(e(1:end-1) / 60 / 60, sm / f_len, 'LineWidth', 2);
        
        % Add to the legend
        legend_cell{end+1} = sprintf('Sequence %d', seq);
    end
    
    axis tight;
    set(gca, 'FontSize', 18);
    xlim([0, 5]);
    xlabel('Time (h)');
    ylabel('Seq/sec');
    ax = gca;
    yl = ax.YLim;

    % Overlay behavioral states if provided
    if plotStates
        stateLegend = plotBehavioralSummary(behavStates, max(yl) + 1, [], [], [], true);
    end
    
    % Set the legend with sequence and state information
    legend([legend_cell stateLegend]);
    ylim(yl);
end
