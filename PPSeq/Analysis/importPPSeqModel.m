function [PPSeq, spike_info] = importPPSeqModel(folder)
% IMPORTPPSEQMODEL - Imports PPSeq data from a specified folder
% If no folder is specified, prompts the user to select a folder.

% Load spike information from the specified folder
load(fullfile(folder, 'spikes_info.mat'), 'spike_info');

% Prompt user to select a folder if none is specified
if nargin == 0
    folder = uigetdir('~/Documents/PPSeq_fork.jl', 'Select folder');
end

% Get folder information and identify subdirectories
folder_info = dir(folder);
subdirs = find([folder_info(3:end).isdir]);

if ~isempty(subdirs)
    % Regex to identify split and offset values from folder names
    split_regex = '.*split([0-9]+)_offset([0-9]*[.]?[0-9]+)';
    matches = regexp({folder_info(subdirs).name}, split_regex, 'tokens');

    % Extract and sort split and offset values
    splitArray = cellfun(@(mat) str2double(mat{1}{1}), matches);
    [~, ord] = sort(splitArray, 'ascend');
    offsetArray = cellfun(@(mat) str2double(mat{1}{2}), matches);
    sortedOffsets = offsetArray(ord);
    sortedDirs = subdirs(ord);

    eventCounter = 0;
    PPSeq = [];
    for part = sortedDirs
        % Import data from each subdirectory
        PPSeq_partial = importPPSeqSingleton(folder_info(part).name, true);
        offset = sortedOffsets(part);

        % Adjust spike times and assignments by the offset
        PPSeq_partial.spikes(:, 2) = PPSeq_partial.spikes(:, 2) + offset;

        PPSeq_partial.assignments = PPSeq_partial.assignments + eventCounter;

        asgn_id = PPSeq_partial.events.assignment_id;
        asgn_id(asgn_id ~= -1) = asgn_id(asgn_id ~= -1) + eventCounter;
        PPSeq_partial.events.assignment_id = asgn_id;

        PPSeq_partial.events.ts = PPSeq_partial.events.ts + offset;

        % Concatenate partial PPSeq data into the main PPSeq
        [PPSeq, eventCounter] = concatenatePPSeq(PPSeq, PPSeq_partial);
    end
else
    % Import data if no subdirectories are found
    PPSeq = importPPSeqSingleton(folder);
end
end


function PPSeq = importPPSeqSingleton(folder)
% IMPORTPPSEQSINGLETON - Imports a single PPSeq dataset from the folder

% Read spike, assignment, and order data
PPSeq.spikes = readmatrix(fullfile(folder, 'spikes.txt'));
PPSeq.assignments = readmatrix(fullfile(folder, 'assignments.txt'));
[~, PPSeq.order] = sort(readmatrix(fullfile(folder, 'order.txt')));

% Read additional data
datapath = fullfile(folder, 'delim_file.txt');
opts = detectImportOptions(datapath);
opts.DataLines = [1 inf];
input = readmatrix(datapath, opts);

% Extract and organize event data
num_units = length(PPSeq.order);
end_size = num_units * 3;
ending = input(end - end_size + 1:end, :);

PPSeq.events.offsets = ending(1:num_units, :);
PPSeq.events.widths = ending(num_units + 1 : 2 * num_units, :);
PPSeq.events.amplitudes = ending(2 * num_units + 1 : end, :);

beginning = input(1 : end - end_size, :);

PPSeq.events.assignment_id = [-1; beginning(:, 1)];
PPSeq.events.ts = [nan; beginning(:, 2)];
PPSeq.events.type = [-1; beginning(:, 3)];

if size(beginning, 2) >= 4
    PPSeq.events.event_amp = [0; beginning(:, 4)];
end
end


function [ppseq, eventCounter] = concatenatePPSeq(ppseq, ppseq_new)
% CONCATENATEPPSEQ - Concatenates two PPSeq datasets

if isempty(ppseq)
    ppseq = ppseq_new;
end

% Concatenate spike and assignment data
ppseq.spikes = [ppseq.spikes; ppseq_new.spikes];
ppseq.assignments = [ppseq.assignments; ppseq_new.assignments];

% Concatenate event data
ppseq.events.assignment_id = [ppseq.events.assignment_id; ppseq_new.events.assignment_id];
ppseq.events.ts = [ppseq.events.ts; ppseq_new.events.ts];
ppseq.events.type = [ppseq.events.type; ppseq_new.events.type];

% Update event counter to the maximum assignment ID
eventCounter = max(ppseq.events.assignment_id);
end
