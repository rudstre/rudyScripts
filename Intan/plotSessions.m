function plotSessions(h5data)
% Define colormap and parameters
colorMap_name = 'turbo'; % Choose colormap: 'parula', 'turbo', or 'jet'
num_lines = 7; % Number of sessions to plot
tetrToPlot = 1; % which of the four tetrodes to plot ([] means all)
unit = 4; % which neuron to plot

colors = colormap(colorMap_name); % Load the specified colormap
colors = colors(round(linspace(1, size(colors, 1), num_lines)), :); % Select evenly spaced colors

% Loop through all units to plot
for session = 1:length(h5data.units{unit})
    hold on % Retain current plot while adding new lines
    
    % Determine if channel is empty
    if isempty(tetrToPlot)
        ts = (1:256)/30; % Time vector for 256 samples, assuming a 30Hz sampling rate
        % Compute mean and standard deviation of spike data
        sessionData = mean(h5data.units{unit}(session).spikes, 2); 
        sessionEr = std(h5data.units{unit}(session).spikes, [], 2); 
    else
        ts = (1:64)/30; % Time vector for 64 samples, assuming a 30Hz sampling rate
        % Compute mean and standard deviation of spike data for a specific channel
        sessionData = mean(h5data.units{unit}(session).spikes(((tetrToPlot - 1) * 64 + 1):(tetrToPlot * 64), :), 2);
        sessionEr = std(h5data.units{unit}(session).spikes(((tetrToPlot - 1) * 64 + 1):(tetrToPlot * 64), :), [], 2);
    end
    
    % Plot with bounded line (shaded error bars)
    boundedline(ts, double(sessionData), double(sessionEr), ...
        'LineWidth', 3, 'Color', colors(session, :), 'alpha','transparency',.1); 
end

% Add a color bar to the plot
colormap(colors); % Set the colormap to the selected colors
cbar = colorbar; % Create the color bar
clim([1 num_lines]); % Adjust color bar limits to match the number of lines

% Customize the color bar ticks and labels
cbar.Ticks = linspace(1, num_lines, num_lines); % Set evenly spaced ticks
cbar.TickLabels = {'8/30', '9/11', '9/24', '10/11', '10/18', '10/25', '10/30'}; % Custom tick labels

% Add axis labels and plot title
xlabel('time (ms)'); % Label for x-axis
ylabel('voltage (uV)'); % Label for y-axis
title('Unit 2'); % Title for the plot
axis tight % Automatically adjust axis limits to fit the data
