function signalChain = extractSignalChain(filePath)
% EXTRACTSIGNALCHAIN Extracts the signal processing chain from a particular OpenEphys recording.
%
%   signalChain = EXTRACTSIGNALCHAIN(filePath) finds the structure.oebin file
%   corresponding with the given path, extracts the signal processing 
%   history for the first channel, and returns it as a cell array of steps 
%   in the signal chain.
%
%   Inputs:
%     - filePath: (Optional) A string specifying the path to the directory
%       containing the structure.oebin file. If not provided, the function prompts the
%       user to select a file.
%
%   Output:
%     - signalChain: A cell array where each element is a step in the signal
%       processing chain.
%
%   Example:
%     % Extract the signal chain from Recording N:
%     chain = extractSignalChain('path/to/recording/n');
%
%     % Prompt the user to select a directory and extract the signal chain:
%     chain = extractSignalChain();

% If no file path is provided, prompt the user to select a directory
if nargin == 0
    filePath = fileSelector();
end

% Read the contents of 'structure.oebin' into a string
rawFile = fileread(fullfile(filePath, 'structure.oebin'));

% Decode the JSON string into a MATLAB structure
jsonStruct = jsondecode(rawFile);

% Extract the signal processing history string for the first channel
signalChainString = jsonStruct.continuous.channels(1).history;

% Split the history string into individual steps and store in a cell array
signalChain = strsplit(signalChainString, ' -> ');

end
