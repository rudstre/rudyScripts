function data_filtered = easyfilt(data, fs, fc, filterType, dim)
% EASYFILT Filters the input data using a Butterworth filter.
% 
%   data_filtered = EASYFILT(data, fs, fc, filterType) filters the input
%   data along the dimension with the largest size using a Butterworth 
%   filter. The filter can be a high-pass, low-pass, band-pass, or 
%   band-stop (notch) filter.
%
%   Inputs:
%     - data: The input data to be filtered (numeric array).
%     - fs: The sampling frequency of the data in Hz.
%     - fc: The cutoff frequency (or frequencies) for the filter. 
%           - For high-pass or low-pass filters, fc should be a scalar.
%           - For band-pass or band-stop filters, fc should be a 2-element vector.
%     - filterType: The type of filter to apply. Can be:
%           - 'high' or 'highpass' for high-pass filter.
%           - 'low' or 'lowpass' for low-pass filter.
%           - 'band' or 'bandpass' for band-pass filter.
%           - 'stop' or 'bandstop' for band-stop (notch) filter.
%     - dim (optional): The dimension along which to apply the filter.
%           - If not specified, the function will filter along the 
%             dimension with the largest size.
%
%   Output:
%     - data_filtered: The filtered data (numeric array of the same size as input).
%
%   Example:
%     % Low-pass filter data with a cutoff frequency of 100 Hz:
%     fs = 1000;  % Sampling frequency in Hz
%     fc = 100;   % Cutoff frequency in Hz
%     data_filtered = easyfilt(data, fs, fc, 'low');
%
%     % Band-pass filter data with cutoff frequencies of 30 Hz and 300 Hz:
%     fc = [30, 300];  % Cutoff frequencies in Hz
%     data_filtered = easyfilt(data, fs, fc, 'band');
%
%   Notes:
%     - The function uses a Butterworth filter with a default order of 2.
%     - For all filter types, this will result in a roll-off of 12 dB per octave.
%     - The cutoff frequencies should be specified in Hz.
%
%   See also BUTTER, FILTER.

%% Input checking and default dimension assignment
% If the dimension (dim) along which to filter is not provided, determine it
% Automatically select the dimension with the largest size
if nargin < 5
    [~, dim] = max(size(data));
end

% Set the order of the filter
ord = 2; % Define the filter order as 2nd-order

%% Determine filter type and validate cutoff frequencies
switch filterType
    case {'high', 'highpass'}
        filterType = 'high'; % Standardize to 'high' for high-pass filter
        if length(fc) ~= 1
            error('Highpass filter needs one frequency!') % High-pass filters require exactly one cutoff frequency
        end
    case {'low', 'lowpass'}
        filterType = 'low'; % Standardize to 'low' for low-pass filter
        if length(fc) ~= 1
            error('Lowpass filter needs one frequency!') % Low-pass filters require exactly one cutoff frequency
        end
    case {'band', 'bandpass'}
        filterType = 'bandpass'; % Standardize to 'bandpass' for band-pass filter
        if length(fc) ~= 2
            error('Bandpass filter needs two frequencies!') % Band-pass filters require exactly two cutoff frequencies
        end
    case {'stop', 'bandstop'}
        filterType = 'stop'; % Standardize to 'stop' for band-stop (notch) filter
        if length(fc) ~= 2
            error('Bandstop filter needs two frequencies!') % Band-stop filters require exactly two cutoff frequencies
        end
end

%% Design the filter and apply it to the data
% Design a Butterworth filter of the specified type and cutoff frequencies
[b, a] = butter(ord, fc/(fs/2), filterType);

% Apply the designed filter to the data along the specified dimension
data_filtered = filter(b, a, data, [], dim);

end
