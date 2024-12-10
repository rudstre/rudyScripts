function groups = generatePairGroups(ncells, ngroups)
    % Generate all possible pairs
    pairs = nchoosek(1:ncells, 2);
    
    % Count occurrences of each cell number in the pairs
    counts = histc(pairs(:), 1:ncells);  % Total frequency of each cell number

    % Initialize groups and their sums
    groups = cell(1, ngroups);           % Each group contains cell numbers
    group_sums = zeros(1, ngroups);      % Each group's sum is the total count

    % Create a list of cell numbers with their counts
    numbers_with_counts = [(1:ncells)', counts];
    
    % Sort by counts in descending order (more frequent first)
    sorted_numbers = sortrows(numbers_with_counts, -2);

    % Assign cell numbers to groups
    for i = 1:size(sorted_numbers, 1)
        num = sorted_numbers(i, 1);     % Cell number
        count = sorted_numbers(i, 2);  % Its frequency count

        % Find the group with the smallest current sum
        [~, min_idx] = min(group_sums);

        % Add the cell number to this group
        groups{min_idx} = [groups{min_idx}, num];

        % Update the group's total sum
        group_sums(min_idx) = group_sums(min_idx) + count;
    end

    % % Display results
    % for i = 1:ngroups
    %     fprintf('Group %d: %s (Sum of counts = %d)\n', i, mat2str(groups{i}), group_sums(i));
    % end
    % 
    % % Display the range of group sums
    % fprintf('Range of group sums: [%d, %d]\n', min(group_sums), max(group_sums));
end
