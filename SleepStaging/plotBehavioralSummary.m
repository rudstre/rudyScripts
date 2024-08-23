function [legend_cell, ax, behavSummary] = plotBehavioralSummary(behavStates, height, ts1, ts2, ax, hrs)
    % Plot behavioral summary for given states
    % 
    % Inputs:
    %   behavStates: Vector containing behavioral states
    %   height: The height of the plot (optional, default = 10)
    %   ts1: Start index for time series (optional, default = 1)
    %   ts2: End index for time series (optional, default = end of behavStates)
    %   ax: Axes handle for the plot (optional, default = current axes)
    %   hrs: Boolean to determine if time is in hours (optional, default = false)
    %
    % Outputs:
    %   legend_cell: Cell array containing legend entries
    %   ax: Axes handle used for plotting
    %   behavSummary: Behavioral summary of the states
    
    % Default values for optional arguments
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

    % Define colors for each state
    cols = [0 0 0; distinguishable_colors(max(behavStates), [1 1 1; 0 0 0])];

    % Generate behavioral summary with 60-second bins
    behavSummary = getBehavioralSummary(behavStates, 5);

    % Determine division factor for time axis (1 for seconds, 3600 for hours)
    div = hrs * 3600 + ~hrs * 1;

    % Trim behavioral summary to specified time range
    behavSummary = behavSummary(ts1:ts2);

    legend_cell = {};
    % Iterate over each state to plot and add to legend
    for state = 0:max(behavSummary)
        % Find epochs for the current state and convert to appropriate units
        stateEpochs = findEpochsFromBinary(behavSummary == state) / div;
        % Add a line with color corresponding to the state
        addBlankLineWithColor(ax, [cols(state + 1, :) 0.15])
        % Add legend entry for the current state
        legend_cell{end + 1} = sprintf('State %d', state);
        % Plot rectangles for each epoch of the current state
        for epoch = stateEpochs'
            rectangle(ax, 'Position', [epoch(1) 0 diff(epoch) height], ...
                'EdgeColor', [1 1 1], 'FaceColor', [cols(state + 1, :) 0.15]);
        end
    end
end
