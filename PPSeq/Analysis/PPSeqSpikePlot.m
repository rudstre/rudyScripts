function [ord, PPSeq, leverData] = PPSeqSpikePlot(PPSeq, sessionData, behavStates, ts1, ts2)
    % Plot spike sequences along with behavioral states and optional lever presses
    %
    % Inputs:
    %   PPSeq: Structure containing pre-processed sequence data
    %   sessionData: Data related to session activities (optional, default = no lever plot)
    %   behavStates: Vector of behavioral states (optional)
    %   ts1: Start time for plotting (optional, default = 1)
    %   ts2: End time for plotting (optional, default = max spike time + 1)
    %
    % Outputs:
    %   ord: Order of spike sequences
    %   PPSeq: Updated PPSeq structure
    %   leverData: Data related to lever presses (if applicable)
    
    % Check for session data to determine if lever plot is needed
    if nargin < 2
        plotLever = false;
    else
        plotLever = true;
    end
    
    % Import PPSeq model if not provided
    if isempty(PPSeq)
        PPSeq = importPPSeqModel;
    end

    % Set up figure and axes
    figPanZoom;
    gcfFullScreen;

    if plotLever
        % Plot lever presses and create corresponding axis for sequences
        [ax_lever, legend_lever, leverData] = plotLeverPresses(sessionData);
        ax_seq = createCopyAxis(ax_lever);
    else
        ax_seq = gca;
    end

    % Map spike events to sequence assignments
    [~, idx] = ismember(PPSeq.assignments, PPSeq.events.assignment_id);
    spikes = PPSeq.spikes;
    spikes(:, 3) = PPSeq.events.type(idx);
    spikes(:, 4) = PPSeq.events.warp(idx);
    spikes(:, 5) = PPSeq.events.event_amp(idx);

    % Set default time range if not provided
    if nargin > 3
        if isa(ts1, 'duration')
            ts1 = seconds(ts1);
        end
        if isa(ts2, 'duration')
            ts2 = seconds(ts2);
        end
    else
        ts1 = 1;
        ts2 = max(spikes(:, 2)) + 1;
    end

    % Filter spikes based on the provided time range
    spikes(~iswithin(spikes(:, 2), ts1, ts2), :) = [];

    %% Reorder spikes
    seqtypes = unique(spikes(:, 3));
    seq_oi = [2, 1]; % Specify sequences of interest

    skip = [];
    evnts = PPSeq.events;

    if isempty(seq_oi)
        spikes(:, 1) = PPSeq.order(spikes(:, 1));
    else
        skip = seqtypes; 
        skip(ismember(skip, seq_oi)) = [];

        amps_oi = evnts.amplitudes(:, seq_oi);
        [~, n] = max(amps_oi, [], 2);
        n(all(amps_oi < -4, 2)) = 0;

        ord = [];
        for i = 1:length(seq_oi)
            cur_seq = seq_oi(i);
            cur_units = find(n == i);
            offsets_oi = evnts.offsets(cur_units, cur_seq);
            [~, idx] = sort(offsets_oi);
            ord = [ord; cur_units(idx)];
        end
        ord = [ord; find(~ismember(1:33, ord))'];
        spikes(:, 1) = arrayfun(@(x) find(ord == x), spikes(:, 1));
    end

    %% Colors
    col_mat = [0, 0, 0; ...
        distinguishable_colors(11, {'w', 'k'})];

    %% Plot sequences
    for i = 1:length(seqtypes)
        seq = seqtypes(i);
        spikesOI = spikes(:, 3) == seq & spikes(:, 5) > 5;
        seq_spikes = spikes(spikesOI, 1:2);
        hold on;
        if ismember(seq, skip)
            scatter(ax_seq, seq_spikes(:, 2) - ts1, seq_spikes(:, 1), 18, [.85, .85, .85], 'filled');
            continue;
        end

        if isempty(seq_spikes)
            scatter(ax_seq, nan, nan, 18, col_mat(i, :), 'filled');
            continue;
        end
        scatter(ax_seq, seq_spikes(:, 2) - ts1, seq_spikes(:, 1), 18, col_mat(i, :), 'filled');
    end

    %% Legend setup
    legend_seq = {'background spikes'};
    for i = 2:length(seqtypes)
        seq = seqtypes(i);
        legend_seq{end + 1} = sprintf('sequence %d', seq);
    end

    legend(ax_seq, legend_seq, 'Location', 'northeast');
    set(ax_seq, 'FontSize', 18);

    % Plot behavioral states if provided
    ax_states = createCopyAxis(ax_seq);
    stateLegend = plotBehavioralSummary(behavStates, max(spikes(:, 1)), ts1, ts2, ax_states);
    legend(ax_states, stateLegend, 'Location', 'southeast');

    % Plot lever presses legend if applicable
    if plotLever
        legend(ax_lever, legend_lever, 'Location', 'southeast');
        set(ax_lever, 'FontSize', 18);
    end

    % Set x and y limits for the plot
    xlim([0 30]);
    ylim([0 max(spikes(:, 1))]);

    %% Plot event timestamps and warp (Optional, commented out)
    % eventsOI = iswithin(evnts.type, 8, 8);
    % scatter(evnts.ts(eventsOI), ...
    %     -1 * evnts.type(eventsOI), ...
    %     1 * 100);
end
