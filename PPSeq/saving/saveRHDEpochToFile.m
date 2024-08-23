function end_time = saveRHDEpochToFile(ustruct, rhdID, start_time, t_len, fs, offset, fp, unit_list, overwrite)
    % Save RHD epoch to a file with spike times for specified units
    %
    % Inputs:
    %   ustruct: Structure array containing unit information
    %   rhdID: Identifier for the RHD file
    %   start_time: Start time of the epoch
    %   t_len: Length of the epoch in seconds
    %   fs: Sampling frequency
    %   offset: Time offset for the output
    %   fp: File path for saving the output (optional)
    %   unit_list: List of units to include in the output
    %   overwrite: Boolean to specify overwriting the file (default = true)
    %
    % Output:
    %   end_time: The end time of the saved epoch

    if nargin < 9
        overwrite = true; % Default to overwriting the file
    end

    % Calculate start and end times in seconds from the RHD file start
    [t_start, rhdID] = getOffsetFromRHDStart(start_time, rhdID);
    t_end = t_start + t_len;
    t_start_s = seconds(t_start) * fs;
    t_end_s = seconds(t_end) * fs;

    % Find valid sessions that match the RHD ID
    validSessions = cellfun(@(x) any(strcmp(rhdID, x)), {ustruct.chainEPhysFile});
    unitLabels = find(validSessions);

    % Filter unit labels based on the provided unit list
    labIdx = arrayfun(@(x) find(unitLabels == x), unit_list);
    unitLabels = unitLabels(labIdx);
    sessionUnits = ustruct(unitLabels);

    % Find the indices of RHD files in the session units
    labels = cellfun(@(x) find(strcmp(rhdID, x)), ...
        {sessionUnits.chainEPhysFile}, 'UniformOutput', false);

    % Assign unit labels to session units
    for i = 1:length(unitLabels)
        sessionUnits(i).unitLabels = unitLabels(i);
    end

    % Extract spike times within the specified time range for each session unit
    for i = 1:length(sessionUnits)
        unit = sessionUnits(i);
        sessionUnits(i).spikeTimes = unit.spikeTimes(...
            ismember(unit.spikeLabels, labels{i}) & ...
            iswithin(unit.spikeTimes, t_start_s, t_end_s))';
    end

    % Combine unit labels and spike times into an output matrix
    unitLabels_all = repelem(1:length(unitLabels), ...
        cellfun(@length, {sessionUnits.spikeTimes}));
    spikeVec = double([unitLabels_all' [sessionUnits.spikeTimes]']);
    output = spikeVec;
    output(:, 2) = output(:, 2) / fs - seconds(t_start) + offset;
    output(:, 2) = round(output(:, 2), 3);

    % Determine the end time of the epoch
    end_time = max(output(:, 2));

    % Get the file path for saving if not provided
    if nargin < 7 || isempty(fp)
        [fname, path] = uiputfile('*.txt', 'Select save location', ...
            '/Users/rudygelb-bicknell/Documents/PPSeq_fork.jl/demo/data/');
        fp = fullfile(path, fname);
    end

    % Save the output matrix to a file, with optional overwrite
    if ~overwrite
        writematrix(output, fp, 'Delimiter', 'tab', 'WriteMode', 'append');
    else
        writematrix(output, fp, 'Delimiter', 'tab');
    end
end
