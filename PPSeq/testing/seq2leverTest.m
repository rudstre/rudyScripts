function good = seq2leverTest(PPSeq, leverData, sequence, leverOrd)
    % Test if lever presses align with specific sequences in the PPSeq data
    %
    % Inputs:
    %   PPSeq: Structure containing event information, including timestamps and types
    %   leverData: Array of structures with lever press times and channels
    %   sequence: Specific sequence type to check against lever presses
    %   leverOrd: Expected order of lever presses for the sequence
    %
    % Outputs:
    %   good: Array indicating if the sequence aligns with lever presses
    %         1 if good alignment, -1 if no lever press, 0 if partial mismatch

    % Extract and sort the timestamps for the specified sequence
    seq_times = sort(PPSeq.events.ts(PPSeq.events.type == sequence));
    validSeq = [1; diff(seq_times) > 1]; % Identify valid sequence starts

    % Determine the start and end times for valid sequences
    t_start = seq_times(logical(validSeq));
    endCandidates = find(validSeq) - 1;
    validSeq_end = [endCandidates(2:end); length(validSeq)];
    t_end = seq_times(validSeq_end);

    % Define time zones for each sequence
    seq_zones = [t_start, t_end] + [-1 1]; % Expand sequence zones by 1 second on both sides
    good = zeros(length(seq_zones), 1); % Initialize the output array

    % Check lever presses against each sequence zone
    for s = 1:length(leverData)
        for i = 1:length(seq_zones)
            % Find lever presses within the sequence zone
            leverIdxs = find(iswithin(leverData(s).onTimes, seq_zones(i, :)'));
            
            if good(i) == 1
                continue; % Skip if already marked as good
            elseif length(leverIdxs) == 2 && all(leverData(s).leverCh(leverIdxs) == leverOrd)
                good(i) = 1; % Mark as good if lever order matches expected sequence
            elseif isempty(leverIdxs)
                good(i) = -1; % Mark as no lever press if none found
            else
                good(i) = 0; % Partial mismatch
            end
        end
    end
end
