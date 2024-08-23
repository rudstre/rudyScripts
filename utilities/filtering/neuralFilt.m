function data = neuralFilt(data, type, fs, f_line)
% NEURALFILT Filters neural data for LFP or ephys (spike) analysis.
%
%   data = NEURALFILT(data, type, fs, f_line) applies the appropriate
%   filtering to neural data based on the specified analysis type (LFP or ephys).
%
%   Inputs:
%     - data: The neural data to be filtered (numeric array).
%     - type: The type of filtering to apply, either 'lfp' or 'ephys'.
%       - 'lfp' applies a bandpass filter (1-100 Hz) and a notch filter at the line frequency.
%       - 'ephys' applies a bandpass filter (300-6000 Hz) and a notch filter at the line frequency.
%     - fs: The sampling frequency of the data in Hz.
%     - f_line: The line frequency to be notched out (in Hz). Defaults to 60 Hz.
%
%   Output:
%     - data: The filtered neural data (numeric array).
%
%   Example:
%     % Filter data for LFP analysis with a default 60 Hz notch:
%     data_filt = neuralFilt(data, 'lfp', fs);
%
%     % Filter data for ephys analysis with a 50 Hz notch:
%     data_filt = neuralFilt(data, 'ephys', fs, 50);

if nargin < 4
    f_line = 60; % Default line frequency to 60 Hz if not provided
end

% Initialize the signal processing chain based on the specified type
switch type
    case 'lfp'
        filterChain(1).type = 'bandpass';
        filterChain(1).fc = [1 100];
        filterChain(2).type = 'notch';
        filterChain(2).fc = f_line;
    case 'ephys'
        filterChain(1).type = 'bandpass';
        filterChain(1).fc = [300 6000];
        filterChain(2).type = 'notch';
        filterChain(2).fc = f_line;
end

% Apply each filter in the signal chain
for f = 1:length(filterChain)
    currentFilter = filterChain(f);
    switch currentFilter.type
        case {'band', 'bandpass', 'high', 'highpass', 'low', 'lowpass'}
            data = easyfilt(data, fs, currentFilter.fc, currentFilter.type);
        case 'notch'
            data = notch(data, fs, currentFilter.fc);
    end
end

end
