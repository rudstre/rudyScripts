function out = iswithin(in, a, b, strict)
    % Check if values in an array are within a specified range
    %
    % Inputs:
    %   in: Array of values to check
    %   a: Lower bound of the range, or a two-element array where a(1) is the lower bound and a(2) is the upper bound
    %   b: Upper bound of the range (optional if a is a two-element array)
    %   strict: Boolean indicating strict inequality (optional, default = false)
    %
    % Output:
    %   out: Logical array indicating whether each element in 'in' is within the specified range

    % Set default value for strict if not provided
    if nargin < 4
        strict = false;
    end

    % Handle case where a two-element array is provided for range limits
    if nargin == 2 && ~isscalar(a)
        b = a(2,:);
        a = a(1,:);
    end

    % Determine if elements are within the specified range
    if strict
        out = in > a & in < b; % Strict inequality
    else
        out = in >= a & in <= b; % Non-strict inequality
    end
end
