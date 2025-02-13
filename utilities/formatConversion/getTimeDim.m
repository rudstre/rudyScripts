function timeDim = getTimeDim(data)
% Identify the time dimension in a multi-dimensional dataset

dataSize = size(data);
[~, timeDim] = max(dataSize);  % Assume the largest dimension is time

% Compute ratios of the time dimension size to other dimensions
sizeRatios = dataSize(timeDim) ./ dataSize;
sizeRatios(timeDim) = [];  % Exclude the time dimension itself

% Ensure the time dimension is significantly larger than others
if any(sizeRatios < 3)
    error('Cannot determine the time dimension reliably.')
end
end
