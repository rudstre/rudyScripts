function [lfp,artifact,frequencies] = calcLFP(data,startTime,endTime,deadEle)

%% Get parameters

% Get sampling rates
ephys = data.ephys;
fs = data.params.fs_ephys_downsampled;

% Convert from duration to samples
startSample = seconds(startTime) * fs + 1; 
endSample = seconds(endTime) * fs; % everything is 1-indexed 

% Calculate window parameters in samples
winStep_seconds = 6;
winLength_seconds = 20;

winLength_sample = winLength_seconds * fs;
winStep_sample = winStep_seconds * fs; % window steps in 1 second increments
padding = winStep_seconds;

if mod(winLength_seconds,2) == 1 || mod(winStep_seconds,2) == 1
    error('Window length must be even')
end

%% Calculate power spectrum for each channel
pwrSpectrum = [];
for ch = 1:size(ephys,1)
    if ismember(ch,deadEle)
        continue
    end

    clc
    fprintf('Calculating LFP for channel %d of %d', ch, size(ephys,1));
    
    [~, frequencies, ts, pwrSpectrum(:,:,end + 1)] = spectrogram(ephys(ch, startSample : endSample), ...
        winLength_sample, winLength_sample - winStep_sample, .5:.5:9, fs, 'yaxis');
end

%% Artifact rejection

% Threshold for artifact recognition
ampThresh = 6e5;

% Calculate total sum across frequencies for each bin
pwrSpectrum_sum = squeeze(sum(pwrSpectrum,1)) / winLength_seconds;

% Calculate mean spectrum across all channels that dont exceed this sum
pwrSpectrum_mean = zeros(size(pwrSpectrum,1),seconds(endTime));
for s = 1:size(pwrSpectrum,2)
    validCh = pwrSpectrum_sum(s,:) < ampThresh;
    sampleMean = squeeze(mean(pwrSpectrum(:,s,validCh),3));
    pwrSpectrum_mean(:, ts(s) : (ts(s) + padding - 1)) = repmat(sampleMean,1,padding);
end

% If any of the frequency means are 0, consider that sample an artifact 
artifact = any(pwrSpectrum_mean == 0, 1);

% Close artifact sections by 20 second radius
strel_artifact = strel('line',20,90);
artifact = imclose(artifact',strel_artifact)';

bands = ...
    [.5, 4; 
    4, 5; 
    5, 7; 
    7, 9];

freqIdxs = iswithin(frequencies,bands');
for i = 1:size(bands,1)
    lfp_bands(i,:) = mean(abs(pwrSpectrum_mean(freqIdxs(:,i),:)).^2,1);
end

frequencies(~iswithin(frequencies,min(bands(:)),max(bands(:)))) = [];
for i = 1:length(frequencies)
    currentBands = freqIdxs(i,:);
    lfp(i,:) = mean(lfp_bands(currentBands,:),1);
end