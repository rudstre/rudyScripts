function h5data = loadh5Data(fp)
% Load and parse data from an HDF5 file into a structured MATLAB format.
%
% Args:
%     fp (string, optional): File path to the HDF5 file. If not provided, a GUI
%     file selector will be opened.
%
% Returns:
%     h5data (struct): A structure containing metadata, unit data, and session
%     information.

% If no file path is provided, open a file selection dialog
if nargin == 0
    fp = fileSelector('Select file'); % Open GUI to select a file
end

% Load metadata and group information from the HDF5 file
info = h5info(fp); % Get metadata about the HDF5 file structure
groupNames = {info.Groups.Name}; % Extract group names from the file
metadata_json = info.Attributes(3).Value; % Load metadata stored as JSON

% Decode JSON metadata and convert start time to MATLAB datetime
h5data = jsondecode(metadata_json); % Parse metadata JSON into a structure
h5data.start_time = datetime(h5data.start_time); % Convert start time to datetime

% Initialize the cell array to store time and data for each unit
h5data.units = [];

% Iterate through each group in the HDF5 file
for gr = 1:length(groupNames)
    % Load the data, labels, and time from the current group
    data = h5read(fp, sprintf('%s/data', groupNames{gr}));
    labels = h5read(fp, sprintf('%s/labels', groupNames{gr}));
    time = h5read(fp, sprintf('%s/time', groupNames{gr}));

    % Skip groups with no data
    if isempty(data)
        continue
    end

    % Identify unique labels (representing different units) in the group
    labels_unq = unique(labels);

    % Process each unique label (unit)
    for u = 1:length(labels_unq)
        unit = labels_unq(u); % Current unit label

        % Extract time values and data corresponding to the current unit
        time_units = time(labels == unit); % Spike times for the current unit
        data_units = data(:, labels == unit); % Spikes for the current unit

        % Split sessions based on a time threshold 
        t_thr_hr = hours(5);
        t_thr_s = 30000 * seconds(t_thr_hr); % in samples
        
        dif = diff(time_units); % Calculate time differences between spikes
        session_idxs = find(dif > t_thr_s); % Identify gaps between sessions

        % Initialize session splitting
        s_start = 1; % Start index of the current session
        sessions = []; % Initialize session structure array

        % Create session structures based on time gaps
        for s = 1:length(session_idxs)
            s_end = session_idxs(s); % End index of the current session
            sessions(s).spikes = data_units(:, s_start:s_end); % Spikes for session
            sessions(s).times = time_units(s_start:s_end); % Times for session
            s_start = s_end + 1; % Update start index for next session
        end

        % Add the final session (after the last gap)
        sessions(s + 1).spikes = data_units(:, s_start:end); % Final spikes
        sessions(s + 1).times = time_units(s_start:end); % Final times

        % Append the sessions for the current unit to h5data
        h5data.units{end + 1} = sessions;
    end
end
end
