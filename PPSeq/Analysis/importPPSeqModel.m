function [PPSeq, spikeInfo] = importPPSeqModel(directory)
    % IMPORTPPSEQMODEL - Imports PPSeq data from a specified directory
    % If no directory is specified, prompts the user to select a directory.

    % Prompt user to select a directory if none is specified
    if nargin == 0
        directory = uigetdir('~/Documents/PPSeq_fork.jl', 'Select folder');
    end

    % Load spike information from the specified directory
    spikeInfo = nan;
    spikeInfoPath = fullfile(directory, 'spikes_info.mat');
    if exist(spikeInfoPath, 'file')
        load(spikeInfoPath, 'spikeInfo');
    end

    % Get directory information and identify subdirectories
    dirInfo = dir(directory);
    subdirs = find([dirInfo.isdir]);

    if length(subdirs) > 2 % Expect two subdirs from '.' and '..'
        % Regex to identify split and offset values from folder names
        splitPattern = '.*split([0-9]+)_offset([0-9]*[.]?[0-9]+)';
        matches = regexp({dirInfo(subdirs).name}, splitPattern, 'tokens');
        hasMatch = cellfun(@length, matches) ~= 0;
        matchedSubdirs = subdirs(hasMatch);

        % Extract and sort split and offset values
        splitValues = cellfun(@(m) str2double(m{1}{1}), matches(hasMatch));
        [~, sortedOrder] = sort(splitValues, 'ascend');
        offsetValues = cellfun(@(m) str2double(m{1}{2}), matches(hasMatch));
        sortedOffsets = offsetValues(sortedOrder);

        modelFolders = dirInfo(matchedSubdirs);
        sortedModelFolders = modelFolders(sortedOrder);

        eventCounter = 0;
        PPSeq = [];
        for partIdx = 1:length(sortedModelFolders)
            clc;
            fprintf('Multiple parts found.\nParsing model part %d of %d...\n', partIdx, length(sortedModelFolders));

            % Import data from each subdirectory
            PPSeqPart = importPPSeqSingleton(fullfile(directory, sortedModelFolders(partIdx).name));
            offset = sortedOffsets(partIdx);

            % Remove background event after the first part
            if partIdx > 1
                PPSeqPart.events.assignment_id = PPSeqPart.events.assignment_id(2:end);
                PPSeqPart.events.type = PPSeqPart.events.type(2:end);
                PPSeqPart.events.ts = PPSeqPart.events.ts(2:end);
                PPSeqPart.events.event_amp = PPSeqPart.events.event_amp(2:end);
                PPSeqPart.events.warp = PPSeqPart.events.warp(2:end);
            end

            % Adjust spike times and assignments by the offset
            PPSeqPart.spikes(:, 2) = PPSeqPart.spikes(:, 2) + offset;
            assignments = PPSeqPart.assignments;
            assignments(assignments ~= -1) = assignments(assignments ~= -1) + eventCounter;
            PPSeqPart.assignments = assignments;

            PPSeqPart.events.assignment_id = PPSeqPart.events.assignment_id + eventCounter;
            PPSeqPart.events.ts = PPSeqPart.events.ts + offset;

            % Concatenate partial PPSeq data into the main PPSeq
            [PPSeq, eventCounter] = concatenatePPSeq(PPSeq, PPSeqPart);
            if ~all(ismember(PPSeq.assignments, PPSeq.events.assignment_id))
                error('Mismatch between assignments and event IDs');
            end
        end
        PPSeq.splits = sortedOffsets;
    else
        % Import data if no subdirectories are found
        PPSeq = importPPSeqSingleton(directory);
    end
end

function PPSeq = importPPSeqSingleton(directory)
    % IMPORTPPSEQSINGLETON - Imports a single PPSeq dataset from the directory

    % Read spike, assignment, and order data
    PPSeq.spikes = readmatrix(fullfile(directory, 'spikes.txt'));
    PPSeq.assignments = readmatrix(fullfile(directory, 'assignments.txt'));
    [~, PPSeq.order] = sort(readmatrix(fullfile(directory, 'order.txt')));

    % Read additional event data
    dataPath = fullfile(directory, 'delim_file.txt');
    opts = detectImportOptions(dataPath);
    opts.DataLines = [1 inf];
    data = readmatrix(dataPath, opts);

    % Extract and organize event data
    numUnits = length(PPSeq.order);
    endDataSize = numUnits * 3;
    endData = data(end - endDataSize + 1:end, :);

    PPSeq.events.offsets = endData(1:numUnits, :);
    PPSeq.events.widths = endData(numUnits + 1 : 2 * numUnits, :);
    PPSeq.events.amplitudes = endData(2 * numUnits + 1 : end, :);

    initialData = data(1 : end - endDataSize, :);
    PPSeq.events.assignment_id = [-1; initialData(:, 1)];
    PPSeq.events.ts = [nan; initialData(:, 2)];
    PPSeq.events.type = [-1; initialData(:, 3)];

    if size(initialData, 2) >= 4
        PPSeq.events.warp = [0; initialData(:, 4)];
    end
    if size(initialData, 2) >= 5
        PPSeq.events.event_amp = [0; initialData(:, 5)];
    end
end

function [ppseq, eventCounter] = concatenatePPSeq(ppseq, ppseqNew)
    % CONCATENATEPPSEQ - Concatenates two PPSeq datasets

    if isempty(ppseq)
        ppseq = ppseqNew;
    else
        % Concatenate spike and assignment data
        ppseq.spikes = [ppseq.spikes; ppseqNew.spikes];
        ppseq.assignments = [ppseq.assignments; ppseqNew.assignments];

        % Concatenate event data
        ppseq.events.assignment_id = [ppseq.events.assignment_id; ppseqNew.events.assignment_id];
        ppseq.events.ts = [ppseq.events.ts; ppseqNew.events.ts];
        ppseq.events.type = [ppseq.events.type; ppseqNew.events.type];
        ppseq.events.event_amp = [ppseq.events.event_amp; ppseqNew.events.event_amp];
        ppseq.events.warp = [ppseq.events.warp; ppseqNew.events.warp];
    end

    % Update event counter to the maximum assignment ID
    eventCounter = max(ppseq.events.assignment_id);
end
