function [epochs_delta,epochs_active,selected_epochs] = sleepStage(rhdData,ustruct,startTime,endTime,unit_list,exportSpikes)
if nargin < 6
    exportSpikes = false;
end
if nargin < 5
    unit_list = [];
end
if nargin < 4 || isempty(endTime)
    endTime = rhdData.params.endTime - rhdData.params.startTime;
end
if nargin < 3 || isempty(startTime)
    startTime = duration(seconds(0));
end
params = rhdData.params;

%% Get LFP
deadEle = [1:4, 13:16, 27:33, 38, 56, 64];
[pwrSpectrum,isArtifact,frequencies] = calcLFP(rhdData, startTime, endTime, deadEle);

%% Get accelerometer data
[activePeriods, accelerometerData] = getActivePeriods(rhdData, startTime, endTime);

%% Get periods of delta
[isDelta,normalizedLFP,lfpFrequencies] = calcDelta(pwrSpectrum, frequencies, activePeriods, isArtifact);
ts = (1 : length(normalizedLFP)) / 60;

%% Plot LFP
axArray = [];

subplot(3,1,1)

imagesc(ts, lfpFrequencies, log10(normalizedLFP + eps))

axis xy

ylabel('Frequency (Hz)')
xlabel('Time (min)')
colormap jet
clim([-1.5,-.25])
ylim([1 10])

axArray(end + 1) = gca;

hold on;

%% Plot delta binary
subplot(3,1,2)

plot(ts, isDelta)

ylim([0,2])

axArray(end + 1) = gca;

%% Plot movement periods
subplot(3,1,3)

plot(ts, activePeriods)
hold on
plot(ts, accelerometerData / max(accelerometerData))

axArray(end + 1) = gca;

%% Link axes
linkaxes(axArray,'x')
axis tight

%% Calculate delta epochs
epochs_delta = findEpochsFromBinary(isDelta);
epochs_active = findEpochsFromBinary(activePeriods');
behav_states = zeros(length(isDelta),1);
behav_states(~activePeriods) = 1;
behav_states(logical(isDelta)) = 2;

%% User-selection of delta epochs to export
if exportSpikes
    subplot(3,1,2)
    epoch_nums = [];
    selected_epochs = [];
    cols = distinguishable_colors(size(epochs_delta,1));
    cnt = 0;
    while true
        cnt = cnt + 1;
        [x,~] = ginput(1);
        if isempty(x)
            break
        end
        [~,current_enum] = find(iswithin(x,epochs_delta'));
        current_epoch = epochs_delta(current_enum,:);
        if ~isempty(current_epoch)
            epoch_nums(end+1) = current_enum;
            selected_epochs(end+1,:) = current_epoch;
            rectangle('Position',[current_epoch(1),0,current_epoch(2)-current_epoch(1),1],'FaceColor',[cols(cnt,:) .7])
            drawnow;
        end
    end

    selected_epochs_sec = seconds(ts(round(selected_epochs * 60)));
    selected_time = diff(selected_epochs,[],2);
    tot_time = sum(selected_time);

    %% Save selected epochs to disk
    [fname,path] = uiputfile('*.txt','Select save location',...
        '/Users/rudygelb-bicknell/Documents/PPSeq_fork.jl/demo/data/');
    fp = fullfile(path,fname);

    end_time = -.5;
    file_offset_sec = seconds(params.acq_offset_s/params.fs_ephys) + startTime;
    for i = 1:size(selected_epochs,1)
        end_time = saveRHDEpochToFile(ustruct, params.chainEphys,...
            selected_epochs_sec(i,1) + file_offset_sec, ...
            selected_epochs_sec(i,2) + file_offset_sec, ...
            params.fs_ephys, end_time + .5, fp, unit_list, i == 1);
    end

    clc
    fprintf('Done! %.1f minutes of data from %d delta epochs saved to disk at %s.\n', ...
        tot_time, size(selected_epochs,1), fp);
end
