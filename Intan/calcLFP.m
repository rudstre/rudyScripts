function [lfpFull, lfpBanded, artifact, frequencies] = calcLFP(data, startTime, endTime, deadChannels)
    % calcLFP - Calculates LFP and bands it into specific frequency ranges
    %
    % Inputs:
    %   data: Structure containing electrophysiological data and parameters
    %   startTime: Start time for LFP calculation
    %   endTime: End time for LFP calculation
    %   deadChannels: Indices of channels considered non-functional
    %
    % Outputs:
    %   lfpFull: Full LFP data across all frequencies
    %   lfpBanded: LFP data filtered into specific frequency bands
    %   artifact: Binary vector indicating artifact presence
    %   frequencies: Frequencies corresponding to the LFP data

    %% Get parameters

    % Get sampling rate
    ephysData = data.ephys;
    samplingRate = data.params.fs_ephys_downsampled;

    % Convert from duration to samples
    startSample = seconds(startTime) * samplingRate + 1; 
    endSample = seconds(endTime) * samplingRate;

    % Calculate window parameters in samples
    winStepSeconds = 1;
    winLengthSeconds = 2;

    winLengthSamples = winLengthSeconds * samplingRate;
    winStepSamples = winStepSeconds * samplingRate; % window steps in 1 second increments
    padding = winStepSamples;

    if any([mod(winLengthSeconds, 2) == 1, mod(winStepSeconds, 2) == 1] & [winLengthSeconds, winStepSeconds] ~= 1) 
        error('Window length must be even')
    end

    %% Calculate power spectrum for each channel
    pwrSpectrum = [];
    for ch = 1:size(ephysData, 1)
        if ismember(ch, deadChannels)
            continue
        end

        clc;
        fprintf('Calculating LFP for channel %d of %d\n', ch, size(ephysData, 1));
        
        [~, frequencies, timeStamps, pwrSpectrum(:,:,end + 1)] = spectrogram(ephysData(ch, startSample:endSample), ...
            winLengthSamples, winLengthSamples - winStepSamples, 1:1:15, samplingRate, 'yaxis');
    end

    %% Artifact rejection

    % Threshold for artifact recognition
    amplitudeThreshold = 6e5;

    % Calculate total sum across frequencies for each time bin
    pwrSpectrumSum = squeeze(sum(pwrSpectrum, 1)) / winLengthSeconds;

    % Calculate mean spectrum across all channels that don't exceed this sum
    lfpFull = zeros(size(pwrSpectrum, 1), seconds(endTime));
    for s = 1:size(pwrSpectrum, 2)
        validChannels = pwrSpectrumSum(s, :) < amplitudeThreshold;
        sampleMean = squeeze(mean(abs(pwrSpectrum(:, s, validChannels)).^2, 3));
        lfpFull(:, timeStamps(s):(timeStamps(s) + padding - 1)) = repmat(sampleMean, 1, padding);
    end

    % If any of the frequency means are 0, consider that sample an artifact 
    artifact = any(lfpFull == 0, 1);

    % Close artifact sections by 20 second radius
    structuringElement = strel('line', 20, 90);
    artifact = imclose(artifact', structuringElement)';

    % Define frequency bands
    bands = [...
        1, 4; ...
        4, 9; ...
        10, 14 ...
        ];

    freqIndices = iswithin(frequencies, bands');
    lfpBanded = zeros(size(bands, 1), size(lfpFull, 2));
    for i = 1:size(bands, 1)
        lfpBanded(i, :) = mean(lfpFull(freqIndices(:, i), :), 1);
    end

    % Remove frequencies outside the defined bands
    frequencies(~iswithin(frequencies, min(bands(:)), max(bands(:)))) = [];
end
