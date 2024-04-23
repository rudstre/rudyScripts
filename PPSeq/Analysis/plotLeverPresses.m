function [ax,leverOn,leverOff] = plotLeverPresses(data,sessions,times,leverOffset,fs_lever)

    if nargin < 5
        fs_lever = 1000;
    end
    alpha = .1;

    leverData = getLeverData(data,sessions,times,leverOffset,fs_lever);

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

