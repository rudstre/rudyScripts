function [PPSeq, spike_info] = importPPSeqModel(prefix)

if nargin == 0
    prefix = uigetdir('~/Documents/PPSeq_fork.jl','Select folder');
end

load(fullfile(prefix,'spikes_info.mat'),'spike_info');

PPSeq.spikes = readmatrix(fullfile(prefix,'spikes.txt'));
PPSeq.assignments = readmatrix(fullfile(prefix,'assignments.txt'));
[~,PPSeq.order] = sort(readmatrix(fullfile(prefix,'order.txt')));

datapath = fullfile(prefix,'delim_file.txt');
opts = detectImportOptions(datapath); opts.DataLines = [1 inf];
input = readmatrix(datapath,opts);

num_units = length(PPSeq.order);
end_size = num_units * 3;
ending = input(end - end_size + 1:end,:);

PPSeq.events.offsets = ending(1:num_units,:);
PPSeq.events.widths = ending(num_units + 1 : (2 * num_units), :);
PPSeq.events.amplitudes = ending(2 * num_units + 1 : end,:);

beginning = input(1 : end - end_size,:);

PPSeq.events.assignment_id = [-1; beginning(:,1)];
PPSeq.events.ts = [nan; beginning(:,2)];
PPSeq.events.type = [-1; beginning(:,3)];

if size(beginning,2) >= 4
    PPSeq.events.event_amp = [0; beginning(:,4)];
end