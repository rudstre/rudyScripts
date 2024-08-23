function filteredData = notch(rawData, samplingRate, lineFreq, filterHarmonics)
% NOTCH Applies a notch filter to remove power line noise at the specified 
% frequency and optionally its first four harmonics.
%
%   filteredData = NOTCH(rawData, samplingRate, lineFreq, filterHarmonics) 
%   applies notch filters to the input data to remove noise at the specified 
%   line frequency and, if specified, its first four harmonics.
%
%   Inputs:
%     - rawData: The input data to be filtered (numeric array).
%     - samplingRate: The sampling frequency of the data in Hz.
%     - lineFreq: The line frequency to be notched out (in Hz). Defaults to 60 Hz.
%     - filterHarmonics: A boolean flag indicating whether to filter the first 
%       four harmonics. If true, the function will remove the fundamental 
%       frequency and the first four harmonics. Defaults to true.
%
%   Output:
%     - filteredData: The filtered data with the line noise and optionally its 
%       harmonics removed (numeric array).
%
%   Example:
%     % Remove 60 Hz line noise and harmonics from the data:
%     filteredData = notch(rawData, samplingRate);
%
%     % Remove only 50 Hz line noise without harmonics:
%     filteredData = notch(rawData, samplingRate, 50, false);

if nargin < 4
    filterHarmonics = true; % Default to filtering harmonics if not provided
end

if nargin < 3
    lineFreq = 60; % Default line frequency to 60 Hz if not provided
end

notchWidth = 2; % Define the width of the notch (2 Hz on either side of the line frequency)
filteredData = rawData; % Initialize the filtered data

% Always filter the fundamental frequency
cutoffFreq = lineFreq + notchWidth * [-1 1]; % Calculate the stopband for the fundamental frequency
filteredData = easyfilt(filteredData, samplingRate, cutoffFreq, 'bandstop'); % Apply the notch filter for the fundamental frequency

% Optionally filter the first four harmonics
if filterHarmonics
    for harmonic = 2:5
        cutoffFreq = harmonic * lineFreq + notchWidth * [-1 1]; % Calculate the stopband for each harmonic
        filteredData = easyfilt(filteredData, samplingRate, cutoffFreq, 'bandstop'); % Apply the notch filter for the harmonic
    end
end
