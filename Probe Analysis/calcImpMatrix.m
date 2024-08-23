function [res, gidx] = calcImpMatrix(imp, highThr)
    % Calculate the impedance matrix by categorizing channels based on impedance values
    %
    % Inputs:
    %   imp: Matrix of impedance values for different channels
    %   highThr: High threshold for impedance categorization (optional, default = 2e6 Ohms)
    %
    % Outputs:
    %   res: Matrix where each row corresponds to a channel, and columns indicate the count of
    %        channels within specific impedance ranges:
    %        Column 1: Impedance below 100k Ohms
    %        Column 2: Impedance between 100k Ohms and highThr
    %        Column 3: Impedance above highThr
    %   gidx: Logical matrix indicating if impedance values are within the medium range (100k to highThr)

    if nargin < 2
        highThr = 2e6; % Set default high threshold if not provided
    end

    % Initialize the result matrix
    res = zeros(size(imp, 2), 3);

    for i = 1:size(imp, 2)
        % Count channels with impedance below 100k Ohms
        res(i, 1) = sum(iswithin(imp(:, i), 0, 1e5));

        % Identify and count channels with impedance between 100k Ohms and highThr
        gidx = iswithin(imp(:, i), 1e5, highThr);
        res(i, 2) = sum(gidx);

        % Count channels with impedance above highThr
        res(i, 3) = sum(iswithin(imp(:, i), highThr, inf));
    end
end
