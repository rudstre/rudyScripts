function [observedVar, nullDist] = computeStability(data)
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
    randshifts = round(length(observed_variances)*rand([2,1]));
    shuffled_data = pairs_data;
    for i = 1:2
        shuffled_data(:,i) = circshift(shuffled_data(:,i),randshifts(i));
    end
    % Compute variance for the shuffled data
    shuffled_variances = var(shuffled_data, 0, 2);

    % Compute the median variance for this permutation
    nullDist(p) = nanmedian(shuffled_variances);
end

% Compare the observed median variance to the null distribution
p_value = mean(nullDist <= observedVar);

fprintf('Observed median variance: %.4f\n', observedVar);
fprintf('p-value: %.4f\n', p_value);
