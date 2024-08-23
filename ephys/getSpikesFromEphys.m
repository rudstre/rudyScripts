function [spikeWaveforms, thresholds] = getSpikesFromEphys(signalData, thresholdMultiplier, detectionDirection, timeWindow)

%% Input checking and default values
% Set default values if arguments are not provided
if nargin < 4
    timeWindow = [-0.5, 1]; % Default time window around the spike in milliseconds
end
if nargin < 3
    detectionDirection = '-'; % Default detection direction ('-' for negative spikes)
end
if nargin < 2
    thresholdMultiplier = 5; % Default multiplier for spike detection threshold
end

%% Determine the sign based on the desired detection direction
% Assign a sign multiplier based on the specified detection direction
switch detectionDirection
    case {'pos', 'positive', '+'}
        signMultiplier = 1; % Positive direction
    case {'neg', 'negative', '-'}
        signMultiplier = -1; % Negative direction
end

% Format the data to a consistent timeseries format
signalData = timeseriesFormat(signalData);

% Calculate the threshold for spike detection using the median absolute deviation (MAD)
thresholds = mad(signalData, [], 1) * thresholdMultiplier;

% Convert the time window into indices based on a 30 kHz sampling rate
timeIndices = (timeWindow(1) * 30 : timeWindow(2) * 30) / 30;

% Initialize a cell array to store spike waveforms for each channel
spikeWaveforms = cell(1, size(signalData, 2));

% Loop through each channel in the signal data
for channelIdx = 1:size(signalData, 2)
    waveforms = []; % Initialize an empty matrix to store spike waveforms for the current channel
    channelData = signalData(:, channelIdx); % Extract the data for the current channel

    % Detect peaks in the data that exceed the threshold, considering the direction
    [peakAmplitudes, peakLocations] = findpeaks(channelData * signMultiplier, ...
        'MinPeakHeight', thresholds(channelIdx), 'MinPeakDistance', 300); % Ensure peaks are sufficiently spaced
    peakLocations(peakAmplitudes > 75) = []; % Remove peaks with amplitudes greater than 75 μV

    % Extract the waveform around each detected peak
    for peakLoc = peakLocations'
        try
            % Capture the waveform around the detected peak within the specified time window
            waveforms(:, end + 1) = channelData(peakLoc + timeIndices * 30);
        end
    end

    % Remove waveforms that do not meet the median constraint criteria
    medianConstraint = [-10; 10]; % Define the acceptable range for the median value of waveforms
    waveforms(:, ~iswithin(median(waveforms, 1)', medianConstraint)) = [];

    % Store the detected waveforms for the current channel
    spikeWaveforms{channelIdx} = waveforms;
end

% Identify channels with a sufficient number of detected spikes (more than 100)
validChannels = find(cellfun(@(x) size(x, 2) > 100, spikeWaveforms));

% Generate distinguishable colors for plotting each valid channel
plotColors = distinguishable_colors(length(validChannels));

% Plot the spike waveforms for each valid channel
figureHandle = figure();
fullScreen(figureHandle); % Maximize the figure window
layout = tiledlayout(figureHandle, 'flow'); % Create a flow layout for subplots
for validIdx = 1:length(validChannels)
    channelIdx = validChannels(validIdx);
    channelSpikes = spikeWaveforms{channelIdx};
    
    % Plot the average waveform with a shaded region representing the standard deviation
    boundedline(timeIndices, mean(channelSpikes, 2), std(channelSpikes, [], 2), ...
        'Color', plotColors(validIdx, :), 'LineWidth', 6, nexttile(layout));
    axis tight
    ylim([-55 25])
    xlabel('Time (ms)')
    ylabel('Voltage (\muV)')
    title(sprintf('Channel %d', channelIdx))
end

% Add a title to the entire plot layout
title(layout, 'Channels with Detected Spikes');
tset(layout);

end
