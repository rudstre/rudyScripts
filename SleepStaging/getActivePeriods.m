function [activePeriodsFinal, accSmoothed] = getActivePeriods(rhdData, startTime, endTime, threshold)
    % getActivePeriods - Identifies active periods using accelerometer data
    %
    % Inputs:
    %   rhdData: Structure containing accelerometer data and parameters
    %   startTime: Start time for analysis
    %   endTime: End time for analysis
    %   threshold: Threshold value for detecting movement (optional, default = 6e-7)
    %
    % Outputs:
    %   activePeriodsFinal: Binary vector indicating active periods after processing
    %   accSmoothed: Smoothed accelerometer data

    %% Set default threshold if not provided
    if nargin < 4
        threshold = 6e-7;
    end

    % Convert from duration to samples
    startSample = seconds(startTime) * rhdData.params.fs_acc_downsampled + 1;
    endSample = seconds(endTime) * rhdData.params.fs_acc_downsampled;

    % Extract accelerometer data for the specified period
    accData = rhdData.acc(startSample:endSample, 2);

    % Smooth the accelerometer data using a moving mean
    smoothingWindow = 20; % Number of samples for smoothing
    accSmoothed = movmean(accData, smoothingWindow, 'omitnan');

    % Determine active periods based on the threshold
    activePeriods = accSmoothed > threshold;

    % Define a structuring element for morphological operations
    structuringElement = strel('line', 60, 90);

    % Open operation to remove small elements
    activePeriodsOpened = imopen(activePeriods, structuringElement);

    % Close operation to fill in gaps
    activePeriodsFinal = imclose(activePeriodsOpened, structuringElement);
end
