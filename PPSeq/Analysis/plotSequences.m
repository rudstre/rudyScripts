function plotSequences(data,sessions,times,sequences,offset)

    %% Input checking
    ts = sequences.ts;
    type = sequences.type;
    col_mat = distinguishable_colors(max(type));

    if nargin < 5
        offset = zeros(1,max(type));
    end

    %% Plot lever presses
    ax = plotLeverPresses(data,sessions,times);

    %% Plot latent events

    y_vals = linspace(1/max(type),1-1/max(type),max(type));

    for seq = 1:max(type)
        scatter(ax,ts(type == seq) - offset(seq),...
            (y_vals(seq)) * ones(nnz(type == seq),1), ...
            32, col_mat(seq,:), 'filled')
    end

    %% Set figure properties
    xlim([25, 37])
    ylim([0, 1])
    
    legend_cell = {'center lever','left lever','right lever'};
    for seq = 1:max(type)
        legend_cell{end+1} = sprintf('sequence %d',seq);
    end
    legend(ax,legend_cell)

    set(ax,'FontSize',18)
