function bitVolts = extractBitVolts(filePath)
% EXTRACTBITVOLTS Extracts the bit-to-microvolt conversion factor from an OpenEphys recording.
%
%   bitVolts = EXTRACTBITVOLTS(filePath) reads the structure.oebin file
%   corresponding to the given path, extracts the bit-to-microvolt 
%   conversion factor for the first channel, and returns it.
%
%   Inputs:
%     - filePath: (Optional) A string specifying the path to the directory
%       containing the structure.oebin file. If not provided, the function 
%       prompts the user to select a directory.
%
%   Output:
%     - bitVolts: A numeric value representing the bit-to-microvolt conversion 
%       factor for the first channel in the recording.
%
%   Example:
%     % Extract the bit-to-microvolt conversion factor from Recording N:
%     conversionFactor = extractBitVolts('path/to/recording/n');
%
%     % Prompt the user to select a directory and extract the conversion factor:
%     conversionFactor = extractBitVolts();

% If no file path is provided, prompt the user to select a directory
if nargin == 0
    filePath = fileSelector();
end

% Read the contents of 'structure.oebin' into a string
rawFile = fileread(fullfile(filePath, 'structure.oebin'));

% Decode the JSON string into a MATLAB structure
jsonStruct = jsondecode(rawFile);

% Extract the bit-to-microvolt conversion factor for the first channel
bitVolts = jsonStruct.continuous.channels(1).bit_volts;

end
