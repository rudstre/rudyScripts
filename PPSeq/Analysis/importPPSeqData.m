function sequences = importPPSeqData()
    input = readmatrix("delim_file.txt",'DELIMITER',',');
    idx_begin = [find(isnan(input(:,2)), 1, 'first'),...
                    find(isnan(input(:,2)), 1, 'last')];
    beginning = input(idx_begin(1):idx_begin(end),1);

    sequences.ts = beginning(1:length(beginning)/2);
    sequences.type = beginning(length(beginning)/2+1:end);

    ending = input(idx_begin(end)+1:end,:);
    len_end = length(ending)/3;

    sequences.offsets = ending(1:len_end,:);
    sequences.widths = ending(len_end+1:(2*len_end),:);
    sequences.amplitudes = ending(2*len_end+1:end,:);
end