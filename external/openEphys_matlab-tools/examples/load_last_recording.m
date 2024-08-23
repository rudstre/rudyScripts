% Define path to the recording
rec_path = uigetdir();

% Create a session (loads all data from the most recent recording)
session = Session(rec_path);

recordNodes_struct = [session.recordNodes{:}];
recordNodes_names = {recordNodes_struct.name};

if length(recording_paths) ~= 1
    nodeIndices = listdlg('ListString',recording_paths);
else
    nodeIndices = 1;
end

% Iterate over the record nodes to access data
data = [];
for nodeIdx = nodeIndices
    node = session.recordNodes{nodeIdx};

    recordings_struct = [node.recordings{:}];

    if length(recordings_struct) ~= 1
        recording_paths = string({recordNodes_struct.name});
        recording_paths = extractBefore(recording_paths, strlength(recording_paths));
        [~,recording_names] = fileparts(recording_paths);
        recIndices = listdlg('ListString',cellstr(recording_names));
    else
        recIndices = 1;
    end
    for recIdx = recIndices

        % 1. Get the first recording
        recording = node.recordings{1,recIdx};

        % 2. Iterate over all continuous data streams in the recording
        streamNames = recording.continuous.keys();

        for k = 1:length(streamNames)

            streamName = streamNames{k};
            disp(streamName)

            % Get the continuous data from the current stream
            data = recording.continuous(streamName);
        end
    end
end