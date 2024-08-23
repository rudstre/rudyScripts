function data = loadOEphysRecordings(path)
% loadOEphysRecordings Loads data from Open Ephys recordings.
%
%   data = loadOEphysRecordings(path) loads the data from Open Ephys
%   recordings located in the specified directory path. If no path is
%   provided, a UI dialog will prompt the user to select a directory.
%
%   The function interacts with Open Ephys sessions, allowing the user to
%   select specific record nodes and recordings. It extracts continuous data
%   streams from the selected recordings and organizes them into a structured
%   output.

% Check if the path is provided; if not, open a directory selection dialog.
if nargin == 0
    path = uigetdir();
end

% Create a session object to load all data from the most recent recording.
session = Session(path);

% Extract the list of record nodes from the session.
recordNodes_struct = [session.recordNodes{:}];  % Flatten the cell array of record nodes into a struct array.
recordNodes_names = {recordNodes_struct.name};  % Extract the names of the record nodes.

% If there are multiple record nodes, prompt the user to select one or more.
% If there's only one record node, automatically select it.
if length(recordNodes_struct) ~= 1
    nodeIndices = listdlg('ListString',recordNodes_names);
else
    nodeIndices = 1;
end

% Initialize an empty array to store the loaded data.
data = [];

% Iterate over the selected record nodes.
for nodeIdx = nodeIndices
    node = session.recordNodes{nodeIdx};  % Access the current record node.

    % Extract the list of recordings from the current record node.
    recordings_struct = [node.recordings{:}];  % Flatten the cell array of recordings into a struct array.
    recording_paths = string({recordings_struct.directory});  % Get the directory paths for each recording.
    recording_paths = extractBefore(recording_paths, strlength(recording_paths));  % Remove trailing slashes.
    [~, recording_names] = fileparts(recording_paths);  % Extract recording names from paths.

    % If there are multiple recordings, prompt the user to select one or more.
    % If there's only one recording, automatically select it.
    if length(recordings_struct) ~= 1
        recIndices = listdlg('ListString',cellstr(recording_names));
    else
        recIndices = 1;
    end

    % Initialize an empty array to store data for the current record node.
    data_node = [];

    % Iterate over the selected recordings.
    for recIdx = recIndices

        % Access the selected recording.
        recording = node.recordings{1, recIdx};

        % Get the names of all continuous data streams in the current recording.
        streamNames = recording.continuous.keys();

        % Initialize an empty array to store data for the current recording.
        data_rec = [];


        % Binary files are stored in little-endian format (uint16). Need to convert
        % to uV
        bitVolts = extractBitVolts(recording_paths(recIdx));

        % Iterate over each continuous data stream.
        for k = 1:length(streamNames)
            streamName = streamNames{k};  % Get the name of the current data stream.

            % Retrieve the continuous data from the current stream and store it.
            data_rec(end+1).data = recording.continuous(streamName);
            data_rec(end).data.samples = double(data_rec(end).data.samples) * bitVolts;
            data_rec(end).stream = streamName;  % Store the stream name.
        end

        % Store the recording data in the node's data structure.
        data_node(end+1).recording = data_rec;
        data_node(end).name = recording_names(recIdx);  % Store the recording name.
        data_node(end).signalChain = extractSignalChain(recording_paths(recIdx));
    end

    % Store the node's data in the main data structure.
    data(end+1).recordNode = data_node;
    data(end).name = recordNodes_names{nodeIdx};  % Store the record node name.
end
