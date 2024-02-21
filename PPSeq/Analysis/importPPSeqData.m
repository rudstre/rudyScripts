input = readmatrix("delim_file.txt",'DELIMITER',',');
idx_begin = [find(isnan(input(:,4)), 1, 'first'),...
    find(isnan(input(:,4)), 1, 'last')];
beginning = input(idx_begin(1):idx_begin(end),1:3);

PPSeq.events.assignment_id = [-1; beginning(:,1)];
PPSeq.events.ts = [nan; beginning(:,2)];
PPSeq.events.type = [-1; beginning(:,3)];

ending = input(idx_begin(end)+1:end,:);
len_end = length(ending)/3;

PPSeq.events.offsets = ending(1:len_end,:);
PPSeq.events.widths = ending(len_end+1:(2*len_end),:);
PPSeq.events.amplitudes = ending(2*len_end+1:end,:);

PPSeq.spikes = readmatrix('spikes.txt');
PPSeq.assignments = readmatrix('assignments.txt');
[~,PPSeq.order] = sort(readmatrix('order.txt'));

PPSeq.assignments(PPSeq.assignments == 0) = -1;

clear input idx_begin beginning ending len_end