function [lfp_full,lfp_banded,artifact,frequencies] = calcLFP(data,startTime,endTime,deadEle)

%% Get parameters

% Get sampling rates
ephys = data.ephys;
fs = data.params.fs_ephys_downsampled;

% Convert from duration to samples
startSample = seconds(startTime) * fs + 1; 
endSample = seconds(endTime) * fs; % everything is 1-indexed 

% Calculate window parameters in samples
winStep_seconds = 1;
winLength_seconds = 2;

winLength_sample = winLength_seconds * fs;
winStep_sample = winStep_seconds * fs; % window steps in 1 second increments
padding = winStep_seconds;

if any([mod(winLength_seconds,2) == 1  mod(winStep_seconds,2) == 1] & [winLength_seconds winStep_seconds] ~= 1) 
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
        winLength_sample, winLength_sample - winStep_sample, 1:1:15, fs, 'yaxis');
end

%% Artifact rejection

% Threshold for artifact recognition
ampThresh = 6e5;

% Calculate total sum across frequencies for each bin
pwrSpectrum_sum = squeeze(sum(pwrSpectrum,1)) / winLength_seconds;

% Calculate mean spectrum across all channels that dont exceed this sum
lfp_full = zeros(size(pwrSpectrum,1),seconds(endTime));
for s = 1:size(pwrSpectrum,2)
    validCh = pwrSpectrum_sum(s,:) < ampThresh;
    sampleMean = squeeze(mean(abs(pwrSpectrum(:,s,validCh)).^2,3));
    lfp_full(:, ts(s) : (ts(s) + padding - 1)) = repmat(sampleMean,1,padding);
end

% If any of the frequency means are 0, consider that sample an artifact 
artifact = any(lfp_full == 0, 1);

% Close artifact sections by 20 second radius
strel_artifact = strel('line',20,90);
artifact = imclose(artifact',strel_artifact)';

bands = ...
    [1, 4; 
    4, 9;
    10 14];

freqIdxs = iswithin(frequencies,bands');
for i = 1:size(bands,1)
    lfp_bands(i,:) = mean(lfp_full(freqIdxs(:,i),:),1);
end

frequencies(~iswithin(frequencies,min(bands(:)),max(bands(:)))) = [];
for i = 1:length(frequencies)
    currentBands = freqIdxs(i,:);
    lfp_banded(i,:) = mean(lfp_bands(currentBands,:),1);
end