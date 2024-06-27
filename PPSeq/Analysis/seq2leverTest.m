function good = seq2leverTest(PPSeq,leverData,sequence,leverOrd)
    
    seq_times = sort(PPSeq.events.ts(PPSeq.events.type == sequence));
    validSeq = [1; diff(seq_times) > 1];

    t_start = seq_times(logical(validSeq));

    endCandidates = find(validSeq) - 1;
    validSeq_end = [endCandidates(2:end); length(validSeq)];
    t_end = seq_times(validSeq_end);

    seq_zones = [t_start,t_end] + [-1 1];
    good = zeros(length(seq_zones),1);
    for s = 1:length(leverData)
        for i = 1:length(seq_zones)
            leverIdxs = find(iswithin(leverData(s).onTimes,seq_zones(i,:)'));
            if good(i) == 1
                continue
            elseif length(leverIdxs) == 2 && all(leverData(s).leverCh(leverIdxs) == leverOrd)
                good(i) = 1;
            elseif isempty(leverIdxs)
                good(i) = -1;
            else
                good(i) = 0;
            end
        end
    end