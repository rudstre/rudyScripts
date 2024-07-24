function behavStates = sleepStage(rhdData,startTime,endTime)
if nargin < 3 || isempty(endTime)
    endTime = rhdData.params.endTime - rhdData.params.startTime;
end
if nargin < 2 || isempty(startTime)
    startTime = duration(seconds(0));
end

%% Get LFP
deadEle = [1:4, 13:16, 27:33, 38, 56, 64];
[lfp_full,lfp_banded,isArtifact,frequencies] = calcLFP(rhdData, startTime, endTime, deadEle);

%% Get accelerometer data
[activePeriods, ~] = getActivePeriods(rhdData, startTime, endTime);

%% Get sleepStates
[behavStates,normalizedLFP,lfpFrequencies] = calcDelta(lfp_full, lfp_banded, frequencies, activePeriods, isArtifact);
ts = (1 : length(normalizedLFP)) / 60;

%% Plot LFP
axArray = [];

subplot(3,1,1)

imagesc(ts, lfpFrequencies, log10(normalizedLFP + eps))

axis xy

ylabel('Frequency (Hz)')
xlabel('Time (min)')
colormap jet
clim([-1.5,-.5])
ylim([1 10])

axArray(end + 1) = gca;

hold on;

%% Plot delta binary
subplot(3,1,[2 3])

plot(ts, behavStates)

ylim([0,max(behavStates) + 1])

axArray(end + 1) = gca;

%% Link axes
linkaxes(axArray,'x')
axis tight