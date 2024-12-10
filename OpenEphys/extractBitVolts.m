function [bitVolts, units] = extractBitVolts(filePath)
% EXTRACTBITVOLTS Extracts the bit-to-volts conversion factors and units from an Open Ephys recording.
%
%   [bitVolts, units] = EXTRACTBITVOLTS(filePath) reads the structure.oebin file
%   corresponding to the given path, extracts the bit-to-volts 
%   conversion factors and units for all channels, and returns them as arrays.
%
%   Inputs:
%     - filePath: (Optional) A string specifying the path to the directory
%       containing the structure.oebin file. If not provided, the function 
%       prompts the user to select a directory.
%
%   Outputs:
%     - bitVolts: A numeric array representing the bit-to-volts conversion 
%       factors for each channel in the recording.
%     - units: A cell array of strings indicating the units ('microvolts' or 'volts')
%       for each channel.
%
%   Example:
%     % Extract the bit-to-volts conversion factors and units from Recording N:
%     [conversionFactors, units] = extractBitVolts('path/to/recording/n');
%
%     % Prompt the user to select a directory and extract the conversion factors and units:
%     [conversionFactors, units] = extractBitVolts();

% If no file path is provided, prompt the user to select a directory
if nargin == 0
    filePath = uigetdir();
end

% Read the contents of 'structure.oebin' into a string
rawFile = fileread(fullfile(filePath, 'structure.oebin'));

% Decode the JSON string into a MATLAB structure
jsonStruct = jsondecode(rawFile);

% Extract the bit-to-volts conversion factors and units for all channels
channels = jsonStruct.continuous.channels;
bitVolts = [channels.bit_volts];
units = {channels.units};

end
