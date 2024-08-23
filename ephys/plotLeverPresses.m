function [ax,lgnd,leverData] = plotLeverPresses(data,PPSeq)

fs_lever = 1000;

alpha = .1;

if isfield(PPSeq,'info')
    numUnits = PPSeq.info.total_units;
    times = PPSeq.info.times;
end

%% Get lever data in right format
leverData = getLeverData(data,times,fs_lever);
shifts = [0,arrayfun(@max,[leverData.onTimes])];

leverOn = arrayfun(@(lvDat) arrayfun(@(lvNum) ...
    lvDat.onTimes(lvDat.leverCh == lvNum), ...
    1:3,'uni',false),leverData,'uni',false);
leverOff = arrayfun(@(lvDat) arrayfun(@(lvNum) ...
    lvDat.offTimes(lvDat.leverCh == lvNum), ...
    1:3,'uni',false),leverData,'uni',false);


%% Plot lever data

% Initialize vars
firstLevPlot = [0,0,0];
startIdxs = ones(length(leverData),3);

% What lever colors do you want
line_cols = {[0,1,0],[1,0,0],[0,0,1]}; % Left = Green, Center = Red, Right = Blue

% Plot one datapoint from each lever first so that legend makes sense
for s = 1:length(leverData)
    for levType = 1:3
        curLeverOn = leverOn{s}{levType} + shifts(s);
        curLeverOff = leverOff{s}{levType} + shifts(s);

        % If data from lever exists, plot first one
        if ~isempty(curLeverOn)

            % Get bounds of first lever press
            firstLeverZone = [curLeverOn(1); ...
                curLeverOff(1) - curLeverOn(1)];

            % Generate visual rectangle for lever press
            rectangle('Position', [firstLeverZone(1), -1, firstLeverZone(2), numUnits + 1],...
                'FaceColor', [line_cols{levType}, alpha], 'EdgeColor', [1,1,1])

            % Rectangle datatype does not appear in legend, so you have to plot
            % an invisible line as well for it to show up
            hold on
            line(NaN, NaN, 'LineWidth', 2, 'Color', [line_cols{levType} alpha + .2]);

            % Keep track of the fact that first lever press was plotted
            firstLevPlot(levType) = 1;
            startIdxs(s,levType) = startIdxs(s,levType) + 1;

            % If there is no lever press of this type, make note
        else
            startIdxs(s,levType) = 0;
        end

        % If one lever of each type has been plotted, stop
        if all(firstLevPlot)
            break
        end

    end
end

% Plot all other lever presses
for s = 1:length(leverData)
    for levType = 1:3
        % Get lever on and lever off times for current lever type
        curLeverOn = leverOn{s}{levType} + shifts(s);
        curLeverOff = leverOff{s}{levType} + shifts(s);

        % Skip lever type if it does not exist for this session
        if isempty(curLeverOn)
            continue
        end

        % Get other lever press bounds

        % If the first session is being plotted, make sure to start at
        % the right starting index (dont re-plot first lever press)
        if s == 1
            leverZones = [curLeverOn(startIdxs(levType):end); ...
                curLeverOff(startIdxs(levType):end)]';
        else
            leverZones = [curLeverOn; curLeverOff]';
        end

        % Plot rectangles
        for l = 1:size(leverZones,1)
            rectangle('Position',...
                [leverZones(l,1), -1, leverZones(l,2) - leverZones(l,1), 101],...
                'FaceColor',[line_cols{levType} alpha],...
                'EdgeColor',[1,1,1])
        end
    end
end

% Set axis, legend, etc
xlim([0 30])
ylim([0 1])

fullLegend = {'left lever','center lever','right lever'};
lgnd = fullLegend(firstLevPlot ~= 0);

ax = gca;

end

