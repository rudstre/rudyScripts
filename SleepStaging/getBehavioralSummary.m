function behavSummary = getBehavioralSummary(behavStates, filterLength)
    % Generate a summary of behavioral states based on a moving average filter
    %
    % Inputs:
    %   behavStates: Vector containing behavioral states
    %   filterLength: Length of the moving average filter
    %
    % Output:
    %   behavSummary: Summary of the dominant behavioral states
    
    pThresh = 0.5; % Threshold for determining dominant state

    % Calculate the moving average percentage for each state
    for state = 1:max(behavStates)
        statePerc(:, state + 1) = movmean(double(behavStates == state), filterLength, 'Endpoints', 'fill');
    end

    behavSummary = NaN(size(behavStates)); % Initialize summary with NaN

    % Identify indices where any state exceeds the threshold
    dominantIdxs = any(statePerc > pThresh, 2);

    % Determine the dominant state at each index
    [~, behavSummary(dominantIdxs)] = max(statePerc(dominantIdxs, :) > pThresh, [], 2);
    
    behavSummary = behavSummary - 1; % Convert to zero-indexed
    behavSummary(behavStates == 0) = 0; % Set state 0 for movement
end
