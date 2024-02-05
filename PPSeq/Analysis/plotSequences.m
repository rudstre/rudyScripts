function plotSequences(data,sessions,times,sequences)

    ts = sequences.ts;
    type = sequences.type;
    offsets = sequences.offsets;
    widths = sequences.widths;
    amps = sequences.amplitudes;

    dt = diff(times,1,2);

    for s = 1:length(sessions)
        cur_session = sessions(s);
        leverTimes = data(cur_session).leverOnTimes;
        valid_on = iswithin(leverTimes, times(s,:) + [-1, 1]);
        leverData(s).onTimes = leverTimes(valid_on) - times(s,1) + sum(dt(1:s-1));
        leverData(s).onTimes = leverData(s).onTimes/1000;

        leverOff = data(cur_session).leverOffTimes;
        valid_off = iswithin(leverOff, times(s,:) + [1, -1]);
        leverData(s).offTimes = leverOff(valid_off) - times(s,1) + sum(dt(1:s-1));
        leverData(s).offTimes = leverData(s).offTimes/1000;

        leverData(s).leverCh = data(cur_session).leverCh(valid_on);
    end

    leverOn = arrayfun(@(lvDat) arrayfun(@(lvNum) ...
        lvDat.onTimes(lvDat.leverCh == lvNum), ...
        1:3,'uni',false),leverData,'uni',false);
    leverOff = arrayfun(@(lvDat) arrayfun(@(lvNum) ...
        lvDat.offTimes(lvDat.leverCh == lvNum), ...
        1:3,'uni',false),leverData,'uni',false);

    startPlot = [0,0,0];
    startIdxs = ones(length(sessions),3);
    line_cols = {'b','r','g'};
    for s = 1:length(sessions)
        for levType = 1:3
            cur_on = leverOn{s}{levType};
            if ~isempty(cur_on)         
                xline(leverOn{s}{levType}(1),['-' line_cols{levType}])
                hold on
                xline(leverOff{s}{levType}(1),['--',line_cols{levType}])
                startPlot(levType) = 1;
                startIdxs(s,levType) = startIdxs(s,levType) + 1;
            else
                startIdxs(s,levType) = 0;
            end
        end
        if all(startPlot)
            break
        end
    end

    for s = 1:length(sessions)
        for levType = 1:3
            cur_data = leverOn{s}{levType};
            if isempty(cur_data)
                continue
            end
            if s == 1
                xline(cur_data(startIdxs(levType):end),...
                    ['--' line_cols{levType}],'HandleVisibility','off')
                xline(cur_data(startIdxs(levType):end),...
                    ['--' line_cols{levType}],'HandleVisibility','off')
            else
                xline(cur_data,...
                    ['--' line_cols{levType}],'HandleVisibility','off')
                xline(cur_data,...
                    ['--' line_cols{levType}],'HandleVisibility','off')
            end
        end
    end

    col_array = {'magenta', 'green','cyan','black','blue','red','yellow'};
    offset = [0,0,0,0,0,0,0];

    for seq = 1:max(type)
        scatter(ts(type == seq) - offset(seq),...
            (1 + .01 * seq) * ones(nnz(type == seq),1), ...
            32, col_array{seq}, 'filled')
    end

    xlim([25, 37])
    ylim([.95, 1.1])
    legend_cell = {'lever 1 on','lever 1 off','lever 2 off','lever 2 off'};
    for seq = 1:max(type)
        legend_cell{end+1} = sprintf('sequence %d',seq);
    end
    legend(legend_cell)
    set(gca,'FontSize',18)