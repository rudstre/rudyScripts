function [ax,lgnd,leverOn,leverOff] = plotLeverPresses(data,spike_info,leverOffset,fs_lever)

    if nargin < 5
        fs_lever = 1000;
    end
    
    alpha = .1;

    sessions = spike_info.sessions;
    numUnits = spike_info.total_units;
    times = spike_info.times;

    %% Get lever data in right format
    leverData = getLeverData(data,sessions,times,leverOffset,fs_lever);

    leverOn = arrayfun(@(lvDat) arrayfun(@(lvNum) ...
        lvDat.onTimes(lvDat.leverCh == lvNum), ...
        1:3,'uni',false),leverData,'uni',false);
    leverOff = arrayfun(@(lvDat) arrayfun(@(lvNum) ...
        lvDat.offTimes(lvDat.leverCh == lvNum), ...
        1:3,'uni',false),leverData,'uni',false);


    %% Plot lever data

    % Initialize vars
    firstLevPlot = [0,0,0];
    startIdxs = ones(length(sessions),3);

    % What lever colors do you want
    line_cols = {[0,1,0],[1,0,0],[0,0,1]}; % Left = Green, Center = Red, Right = Blue

    % Plot one datapoint from each lever first so that legend makes sense
    for s = 1:length(sessions)
        for levType = 1:3
            curLever = leverOn{s}{levType};

            % If data from lever exists, plot first one
            if ~isempty(curLever) 

                % Get bounds of first lever press
                firstLeverZone = [leverOn{s}{levType}(1); ...
                    leverOff{s}{levType}(1) - leverOn{s}{levType}(1)];

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
    for s = 1:length(sessions)
        for levType = 1:3
            % Get lever on and lever off times for current lever type
            data_on = leverOn{s}{levType};
            data_off = leverOff{s}{levType};

            % Skip lever type if it does not exist for this session
            if isempty(data_on)
                continue
            end

            % Get other lever press bounds

            % If the first session is being plotted, make sure to start at
            % the right starting index (dont re-plot first lever press)
            if s == 1
                leverZones = [data_on(startIdxs(levType):end); data_off(startIdxs(levType):end)]';
            else
                leverZones = [data_on; data_off]';
            end

            % Plot rectangles
            for l = 1:size(leverZones,1)
                rectangle('Position',[leverZones(l,1),-1,leverZones(l,2)-leverZones(l,1),101],...
                    'FaceColor',[line_cols{levType} alpha],'EdgeColor',[1,1,1])
            end
        end
    end

    % Set axis, legend, etc
    xlim([0 30])
    ylim([0 1])

    fullLegend = {'center lever','left lever','right lever'};
    lgnd = fullLegend(firstLevPlot ~= 0);
    
    ax = gca;

end

