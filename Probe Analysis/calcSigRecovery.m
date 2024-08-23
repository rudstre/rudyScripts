function [goodSignal, percentageAlive, recoveryMean] = calcSigRecovery(data, impedances, goodIndices_start, goodIndices_end)
    % Calculate signal recovery metrics and percentage of alive signals based on impedance
    %
    % Inputs:
    %   data: Matrix of signal data (channels x samples)
    %   impedances: Array of impedance values for each channel
    %   goodIndices: Indices of channels considered good
    %
    % Outputs:
    %   goodSignal: Array indicating good signal channels
    %   percentageAlive: Array of mean percentages of alive signals for each impedance range
    %   recoveryMean: Mean recovery value for each channel

    % Bandpass filter settings
    fc_bandpass = [395 415]; % Frequency range in Hz
    fs = 20000; % Sampling frequency
    [b_bandpass, a_bandpass] = butter(2, fc_bandpass / (fs / 2), 'bandpass'); % 2nd-order Butterworth filter

    % Filter the data using the bandpass filter
    filteredData = filter(b_bandpass, a_bandpass, data, [], 2);

    % Calculate the peak-to-peak amplitude using moving maximum and minimum
    movingMax = movmax(filteredData, 0.5 * fs, 2);
    movingMin = movmin(filteredData, 0.5 * fs, 2);
    peakToPeak = movingMax - movingMin;

    % Calculate recovery metric and average it across samples
    recovery = peakToPeak / 500;
    recoveryMean = mean(recovery, 2);

    % Initialize the results
    percentageAlive = [];

    % Calculate the mean recovery percentage for each impedance range
    for i = 0:15:2000
        % Determine indices for current impedance range
        impedanceIndices = iswithin(impedances(goodIndices_start) / 1e3, i - 50, i + 50);

        % Calculate good signal channels for current range
        goodSignal = goodIndices_end(impedanceIndices);
        percentageAlive(end + 1) = mean(goodSignal);
    end
end
