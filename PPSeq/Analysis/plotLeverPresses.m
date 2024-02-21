function [ax,leverOn,leverOff] = plotLeverPresses(data,sessions,times,leverOffset)

    alpha = .1;
    dt = diff(times,1,2);

    for s = 1:length(sessions)
        cur_session = sessions(s);
        leverTimes = data(cur_session).leverOnTimes;
        valid_on = iswithin(leverTimes, times(s,:) + [-1, 1]);
        leverData(s).onTimes = leverTimes(valid_on);
        
        leverOff = data(cur_session).leverOffTimes;
        off_start = find(leverOff - leverData(s).onTimes(1) > 0,1);
        off_end = off_start + nnz(valid_on);
        leverData(s).offTimes = leverOff(off_start:off_end);

        leverData(s).onTimes = (leverData(s).onTimes - times(s,1) + sum(dt(1:s-1)) + leverOffset*1000)/1000;
        leverData(s).offTimes = (leverData(s).offTimes - times(s,1) + sum(dt(1:s-1)) + leverOffset*1000)/1000;

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
    line_cols = {[0,1,0],[1,0,0],[0,0,1]};
    for s = 1:length(sessions)
        for levType = 1:3
            cur_on = leverOn{s}{levType};
            if ~isempty(cur_on)
                firstLeverZone = [leverOn{s}{levType}(1); leverOff{s}{levType}(1) - leverOn{s}{levType}(1)];
                rectangle('Position',[firstLeverZone(1),-1,firstLeverZone(2),101],...
                    'FaceColor',[line_cols{levType} alpha],'EdgeColor',[1,1,1])
                hold on
                line(NaN,NaN,'LineWidth',2,'Color',[line_cols{levType} alpha+.2]);
                startPlot(levType) = 1;
                startIdxs(s,levType) = startIdxs(s,levType) + 1;
            else
                startIdxs(s,levType) = 0;
            end
            if all(startPlot)
                break
            end
        end
    end

    for s = 1:length(sessions)
        for levType = 1:3
            data_on = leverOn{s}{levType};
            data_off = leverOff{s}{levType};
            if isempty(data_on)
                continue
            end
            if s == 1
                leverZones = [data_on(startIdxs(levType):end);data_off(startIdxs(levType):end)]';
            else
                leverZones = [data_on;data_off]';
            end
            for l = 1:size(leverZones,1)
                rectangle('Position',[leverZones(l,1),-1,leverZones(l,2)-leverZones(l,1),101],...
                    'FaceColor',[line_cols{levType} alpha],'EdgeColor',[1,1,1])
            end
        end
    end

    xlim([0 30])
    ylim([0 1])
    legend('center lever','left lever','right lever')
    ax = gca;

end

