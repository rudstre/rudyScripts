function opt = initializeDataForAnimal(animalDataPath,spikes)
if nargin < 1
    animalDataPath = fileSelector;
end
if nargin < 2
    spikes = saveSpikesInChunks(animalDataPath);
end

pairs = nchoosek(1:length(spikes),2);
recLen = milliseconds(max(cellfun(@length,spikes)));

spike_path = input('Enter path where spikes will be on cluster: ', 's');
save_path = input('Enter path where results will be saved on cluster: ', 's');
opt = createCorrelationsOptStruct(pairs,recLen,'spike_path',spike_path,'save_path',save_path);

