function res = combineResults(resPath)
% combineResults: Combines multiple result files located in a directory into
% aggregated arrays of correlation measures and their corresponding lags.

% If no input is given, prompt the user to select a directory
if nargin == 0
    resPath = uigetdir;
end

% Get the list of files in the specified directory
files = dir(resPath);

% Loop through all files starting from index 3 because:
% files(1) = '.' and files(2) = '..' are directory references, not data files
for i = 3:length(files)
    fprintf('Loading file %d of %d...\n', i, length(files))
    % Load the 'results' structure from the .mat file
    data = load(fullfile(resPath, files(i).name)).results;

    % Extract z-score arrays for negative and positive lags
    zn = data.zscore_neg;
    zp = data.zscore_pos;
    ln = data.zscore_lag_neg;
    lp = data.zscore_lag_pos;

    % Replace NaNs with 0 in all arrays
    zn(isnan(zn)) = 0;
    zp(isnan(zp)) = 0;
    ln(isnan(ln)) = 0;
    lp(isnan(lp)) = 0;

    % If this is the first file, initialize the cumulative arrays
    if ~exist('zneg','var')
        [zneg, zpos, lneg, lpos] = deal(zeros(size(zn)));
    end

    % Add current file's data to the cumulative arrays
    if isempty(zn)
        continue
    end
    zneg = zneg + zn;
    zpos = zpos + zp;
    lneg = lneg + ln;
    lpos = lpos + lp;
end

% Adding reverse pairs to matrix
[x, y, z] = ind2sub(size(zneg), find(zneg == 0));
for i = 1:length(x)
    xi = x(i);
    yi = y(i);
    zi = z(i);

    if any([zneg(xi, yi, zi), zpos(xi, yi, zi), lneg(xi, yi, zi), lpos(xi, yi, zi)])
        error('Problem!!')
    end

    % Adjust symmetry: if zneg at (xi, yi) is zero, try to mirror from (yi, xi).
    % Similarly handle zpos, lneg, and lpos to maintain consistent symmetrical structure.
    % Note: lneg and lpos get their sign flipped for the reversed pair.
    zneg(xi, yi, zi) = zneg(yi, xi, zi);
    zpos(xi, yi, zi) = zpos(yi, xi, zi);
    lneg(xi, yi, zi) = -lneg(yi, xi, zi);
    lpos(xi, yi, zi) = -lpos(yi, xi, zi);
end

% Convert zeros or infinities back into NaNs.
% This step ensures that invalid or missing data are clearly marked as NaN.
zneg(~zneg | isinf(abs(zneg))) = nan;
zpos(~zpos | isinf(abs(zpos))) = nan;
lneg(~lneg | isinf(abs(lneg))) = nan;
lpos(~lpos | isinf(abs(lpos))) = nan;

% Store the final combined results into the output structure
res.zneg = zneg;
res.zpos = zpos;
res.lneg = lneg;
res.lpos = lpos;

end
