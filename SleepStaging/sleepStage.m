function behavStates = sleepStage(rhdData, startTime, endTime)
    % sleepStage - Determines the behavioral states (sleep stages) from LFP and accelerometer data
    %
    % Inputs:
    %   rhdData: Structure containing RHD data including LFP and accelerometer data
    %   startTime: Starting time for analysis (optional, default is 0)
    %   endTime: Ending time for analysis (optional, default is the end of the recording)
    %
    % Outputs:
    %   behavStates: Vector of identified behavioral states

    % Set default endTime if not provided
    if nargin < 3 || isempty(endTime)
        endTime = rhdData.params.endTime - rhdData.params.startTime;
    end
    % Set default startTime if not provided
    if nargin < 2 || isempty(startTime)
        startTime = duration(seconds(0));
    end

    %% Calculate LFP data
    deadElectrodes = [1:4, 13:16, 27:33, 38, 56, 64];
    [lfpFull, lfpBanded, isArtifact, frequencies] = calcLFP(rhdData, startTime, endTime, deadElectrodes);

    %% Get accelerometer data
    [activePeriods, ~] = getActivePeriods(rhdData, startTime, endTime);

    %% Get sleep states
    [behavStates, normalizedLFP, lfpFrequencies] = calcDelta(lfpFull, lfpBanded, frequencies, activePeriods, isArtifact);
    ts = (1 : length(normalizedLFP)) / 60; % Time in minutes

    %% Plot LFP
    axArray = [];

    % Plot LFP spectrogram
    subplot(3,1,1)
    imagesc(ts, lfpFrequencies, log10(normalizedLFP + eps))
    axis xy
    ylabel('Frequency (Hz)')
    xlabel('Time (min)')
    colormap jet
    clim([-1.5, -0.5])
    ylim([1 10])
    axArray(end + 1) = gca;
    hold on;

    %% Plot behavioral states (sleep stages)
    subplot(3,1,[2 3])
    plot(ts, behavStates)
    ylim([0, max(behavStates) + 1])
    ylabel('Behavioral States')
    xlabel('Time (min)')
    axArray(end + 1) = gca;

    %% Link axes for synchronized zooming and panning
    linkaxes(axArray, 'x')
    axis tight
end
