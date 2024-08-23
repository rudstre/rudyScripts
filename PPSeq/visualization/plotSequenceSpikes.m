assign_unq = unique(assignments);
assign_unq = assign_unq(2:end);

offsets_cur = sequences.offsets(:,2);
[offsets_sorted,units_reordered] = sort(offsets_cur,'ascend');

for j = 2:2%unique(sequences.type)
    seq_asgn{j} = assign_unq(sequences.type == j);
    seq_time{j} = sequences.ts(sequences.type == j);

    for i = 1:size(seq_asgn{j},1)
        seq_spikes{i,j} = spikes(assignments == seq_asgn{j}(i),:);
    end

    figure

    for i = 1:length(seq_spikes{j})
        scatter(seq_spikes{i,j}(:,1)-seq_time{j}(i),units_reordered(seq_spikes{i,j}(:,2)),'filled')
        hold on
        scatter(offsets_sorted,1:61)
        ylim([1 61])
        xlim([-4 3])
        pause
    end
end