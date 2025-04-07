function [timeOffset, rhdFilename] = getOffsetFromRHDStart(startTime, rhdFilename)
% Computes the time offset between a given start time and the RHD file timestamp.
%
% INPUT:
%   startTime   - Reference start time (datetime format)
%   rhdFilename - (Optional) Name of the RHD file (without extension)
%
% OUTPUT:
%   timeOffset  - Difference between the provided startTime and the timestamp from the RHD file
%   rhdFilename - The selected or provided RHD filename (without extension)

% Prompt user to select an RHD file if not provided
if nargin < 2 || isempty(rhdFilename)
    selectedFile = fileSelector('Select RHD file of interest:');
    [~, rhdFilename] = fileparts(selectedFile);
end

% Convert RHD filename timestamp to datetime
fileStartTime = tick2datetime(str2double(rhdFilename));

% Compute the time offset
timeOffset = startTime - fileStartTime;
end
