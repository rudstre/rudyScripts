
function [PPSeq, spike_info] = importPPSeqModel(folder)
% IMPORTPPSEQMODEL - Imports PPSeq data from a specified folder
% If no folder is specified, prompts the user to select a folder.

% Prompt user to select a folder if none is specified
if nargin == 0
    folder = uigetdir('~/Documents/PPSeq_fork.jl', 'Select folder');
end

% Load spike information from the specified folder
spike_info = nan;
spike_info_path = fullfile(folder, 'spikes_info.mat');
if exist(spike_info_path,'file')
    load(fullfile(folder, 'spikes_info.mat'), 'spike_info');
end

% Get folder information and identify subdirectories
folder_info = dir(folder);
subdirs = find([folder_info.isdir]);

if length(subdirs) > 2 % two expected from '.' and '..'
    % Regex to identify split and offset values from folder names
    split_regex = '.*split([0-9]+)_offset([0-9]*[.]?[0-9]+)';
    matches = regexp({folder_info(subdirs).name}, split_regex, 'tokens');
    isMatch = cellfun(@length,matches) ~= 0;
    subdirs_match = subdirs(isMatch);

    % Extract and sort split and offset values
    splitArray = cellfun(@(mat) str2double(mat{1}{1}), matches(isMatch));
    [~, ord] = sort(splitArray, 'ascend');
    offsetArray = cellfun(@(mat) str2double(mat{1}{2}), matches(isMatch));
    sortedOffsets = offsetArray(ord);

    model_folders = folder_info(subdirs_match);
    models_sorted = model_folders(ord);

    eventCounter = 0;
    PPSeq = [];
    for part = 1:length(models_sorted)
        clc
        fprintf('Multiple parts found.\nParsing model part %d of %d...\n',...
            part,length(models_sorted))

        % Import data from each subdirectory
        PPSeq_partial = ...
            importPPSeqSingleton(fullfile(folder,models_sorted(part).name));
        offset = sortedOffsets(part);

        % Strip out background event after first part
        if part > 1
            PPSeq_partial.events.assignment_id = PPSeq_partial.events.assignment_id(2:end);
            PPSeq_partial.events.type = PPSeq_partial.events.type(2:end);
            PPSeq_partial.events.ts = PPSeq_partial.events.ts(2:end);
            PPSeq_partial.events.event_amp = PPSeq_partial.events.event_amp(2:end);
            PPSeq_partial.events.warp = PPSeq_partial.events.warp(2:end);
        end

        % Adjust spike times and assignments by the offset
        PPSeq_partial.spikes(:, 2) = PPSeq_partial.spikes(:, 2) + offset;

        asgnments = PPSeq_partial.assignments;
        asgnments(asgnments ~= -1) = asgnments(asgnments ~= -1) + eventCounter;
        PPSeq_partial.assignments = asgnments;

        PPSeq_partial.events.assignment_id = PPSeq_partial.events.assignment_id + eventCounter;

        PPSeq_partial.events.ts = PPSeq_partial.events.ts + offset;

        % Concatenate partial PPSeq data into the main PPSeq
        [PPSeq, eventCounter] = concatenatePPSeq(PPSeq, PPSeq_partial);
        if ~all(ismember(PPSeq.assignments,PPSeq.events.assignment_id))
            sprintf('test')
        end
    end
    PPSeq.splits = sortedOffsets;
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
    PPSeq.events.warp = [0; beginning(:, 4)];
end
if size(beginning, 2) >= 5
    PPSeq.events.event_amp = [0; beginning(:, 5)];
end
end


function [ppseq, eventCounter] = concatenatePPSeq(ppseq, ppseq_new)
% CONCATENATEPPSEQ - Concatenates two PPSeq datasets

if isempty(ppseq)
    ppseq = ppseq_new;
else
    % Concatenate spike and assignment data
    ppseq.spikes = [ppseq.spikes; ppseq_new.spikes];
    ppseq.assignments = [ppseq.assignments; ppseq_new.assignments];

    % Concatenate event data
    ppseq.events.assignment_id = [ppseq.events.assignment_id; ppseq_new.events.assignment_id];
    ppseq.events.ts = [ppseq.events.ts; ppseq_new.events.ts];
    ppseq.events.type = [ppseq.events.type; ppseq_new.events.type];
    ppseq.events.event_amp = [ppseq.events.event_amp; ppseq_new.events.event_amp];
    ppseq.events.warp = [ppseq.events.warp; ppseq_new.events.warp];
end

% Update event counter to the maximum assignment ID
eventCounter = max(ppseq.events.assignment_id);
end
