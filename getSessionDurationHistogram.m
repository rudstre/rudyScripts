function getSessionDurationHistogram(data)
% Get valid sessions
validSM = [3,4,5,6,7,18,16,17];
isvalid = ismember([data.SM],validSM);

% Compute durations
for i = 1:length(data)
    if ~isvalid(i)
        durations(i) = nan;
        continue
    end
    durations(i) = filterUnits(data(i));
end

% Plot histogram
histogram(durations)
title('Histogram of session duration in minutes assuming ms timesteps')
xlabel('length of session (minutes)')
ylabel('count')
set(gca,'FontSize',18)
