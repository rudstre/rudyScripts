function spikes = saveSpikesInChunks(spikeTrainPath)
% SAVESPIKESINCHUNKS Loads a compiled spike train, processes it into binned spikes, 
% and saves the results in separate .mat files.
%
% Usage:
%   saveSpikesInChunks()             % Prompts user to select a .mat file and a directory to save outputs.
%   saveSpikesInChunks(spikeTrainPath) % Uses the provided .mat file path.
%
% Inputs:
%   spikeTrainPath - (optional) Path to the .mat file containing 'CompiledSpikeTrain'.
%
% The function will:
% 1. Load the 'CompiledSpikeTrain' variable from the specified .mat file.
% 2. Convert spike times to binned spikes using 'spikeTimesToBins'.
% 3. Prompt the user to select a directory to save the output files.
% 4. Save each cell of the processed spikes as a separate .mat file.

    % If no input is given, prompt the user to select the file containing 'CompiledSpikeTrain'
    if nargin == 0
        spikeTrainPath = fileSelector('Select path to spikes');
    end

    % Load 'CompiledSpikeTrain' from the specified file
    S = load(spikeTrainPath, 'SessionSplitSpikeTrains');
    if ~isfield(S, 'SessionSplitSpikeTrains')
        error('The selected file does not contain ''SessionSplitSpikeTrains''.');
    end
    
    spikeTrain = S.SessionSplitSpikeTrains;
    
    fprintf('Computing spike time array...\n');
    % Convert spike times to binned spikes
    for i = 1:size(spikeTrain,2)
        [spikes(:,i),t_start(i)] = spikeTimesToBins(spikeTrain(:,i));
    end

    % Prompt user to select the output directory
    outputDir = uigetdir([], 'Select output directory for saved spike files');
    if isequal(outputDir,0)
        error('No output directory selected. Aborting.');
    end

    numSpikes = length(spikes);
    for i = 1:numSpikes
        fp = fullfile(outputDir, sprintf('spikes_%d.mat', i));
        fprintf('Saving file %d of %d to %s...\n', i, numSpikes, fp);
        
        sp.spikes = spikes(i,:);
        sp.t = t_start;
        save(fp, 'sp');
    end
end
