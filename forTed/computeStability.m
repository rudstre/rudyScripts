function [observedVar, nullDist, p_value] = computeStability(data)
[nx, ny, nt] = size(data);

% Flatten the (nx, ny) pairs into a single dimension for convenience
pairs_data = convertPairsFromSqFm3d(data);  % Now size is [nx*ny, 3]

% Compute observed variance for each pair (row), then median across all pairs
observed_variances = var(pairs_data, 0, 2); % variance along the time dimension
observedVar = nanmedian(observed_variances);

% Set the number of permutations
nPerm = 10000;
nullDist = nan(nPerm, 1);

for p = 1:nPerm
    clc
    fprintf('Null %d of %d...\n',p,nPerm);
    colToShuffle = size(pairs_data,2) - 1;
    randshifts = round(length(observed_variances)*rand([colToShuffle,1]));
    shuffled_data = pairs_data;
    for i = 1:colToShuffle
        shuffled_data(:,i) = circshift(shuffled_data(:,i),randshifts(i));
    end
    % Compute variance for the shuffled data
    shuffled_variances = var(shuffled_data, 0, 2);

    % Compute the median variance for this permutation
    nullDist(p) = nanmedian(shuffled_variances);
end

% Compare the observed median variance to the null distribution
p_value = mean(nullDist <= observedVar);


%% Plot
histogram(nullDist,'Normalization','Probability');
xline(observedVar,'--b','LineWidth',3)

title('Variation in z-score compared to shuffled distribution for Animal T362')
xlabel('Median variance in z-score across time')
ylabel('Probability')

xlim([1 10])
tset

text(3.8355,491.8085,'Observed variance','FontSize',12)