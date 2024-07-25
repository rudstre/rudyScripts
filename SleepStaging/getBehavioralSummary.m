function behavSummary = getBehavioralSummary(behavStates,filterLength)

pThresh = .5;

for state = 1:max(behavStates)
    statePerc(:,state + 1) = movmean(behavStates == state,filterLength);
end

behavSummary = NaN(size(behavStates));

dominantIdxs = any(statePerc > pThresh,2);
[~,behavSummary(dominantIdxs)] = max(statePerc(dominantIdxs,:) > pThresh,[],2);
behavSummary = behavSummary - 1; % zero indexed
behavSummary(behavStates == 0) = 0;
