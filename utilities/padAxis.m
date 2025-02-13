function padAxis(varargin)
    p = inputParser;

    % Define parameters with validation
    addParameter(p, 'xaxis', [], @(x) isnumeric(x) && any(ismember(numel(x), [0 1 2])));
    addParameter(p, 'yaxis', [], @(x) isnumeric(x) && any(ismember(numel(x), [0 1 2])));
    
    % Parse input arguments
    parse(p, varargin{:});
    
    % Extract results
    xpad = p.Results.xaxis;
    ypad = p.Results.yaxis;

    % Check if the current figure is open and valid axes exist
    fig = gcf;  % Get the current figure handle
    if isempty(fig)
        warning('No open figure found.');
        return;
    end
    
    % Get the current axes (if any)
    ax = gca;
    if isempty(ax) || ~ishandle(ax)  % Check if axes are valid
        warning('No valid axes found in the current figure.');
        return;
    end

    % Get current axis limits
    xl_init = get(ax, 'Xlim');
    yl_init = get(ax, 'Ylim');
    
    % Get tight limits for reference
    axis tight;
    xl_tight = get(ax, 'Xlim');
    yl_tight = get(ax, 'Ylim');

    % Apply padding for x-axis if specified (on tight limits)
    if ~isempty(xpad)
        if isscalar(xpad)
            xpad = [xpad xpad];  % Convert scalar to vector
        end
        updateAxisLimits(ax, 'XLim', xpad, xl_tight);  % Apply padding to tight limits
    else
        set(ax, 'XLim', xl_init);  % Revert to tight limits if no padding
    end

    % Apply padding for y-axis if specified (on tight limits)
    if ~isempty(ypad)
        if isscalar(ypad)
            ypad = [ypad ypad];  % Convert scalar to vector
        end
        updateAxisLimits(ax, 'YLim', ypad, yl_tight);  % Apply padding to tight limits
    else
        set(ax, 'YLim', yl_init);  % Revert to tight limits if no padding
    end
end

function updateAxisLimits(ax, axisType, padding, tightLimits)
    % Helper function to update axis limits
    if numel(padding) == 2
        % Apply padding to tight limits
        set(ax, axisType, ([-1 1] .* diff(tightLimits) .* padding / 2) + tightLimits);
    else
        set(ax, axisType, tightLimits);  % Revert to tight limits if no padding
    end
end
