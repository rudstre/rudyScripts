function [lfp_mean,artifact,freqs,t] = calcLFP(ephys,t_start,t_end,deadEle)

%% Calculate LFP
fs_ds = 300; % downsampled sampling rate is fs/100
step_s = 1 * fs_ds; % window steps in 1 second increments
win_s = 5 * fs_ds; % window length is 5 seconds (80% overlap between windows)
lfp = [];

for ch = 1:size(ephys,1)
    if ismember(ch,deadEle)
        continue
    end
    clc
    
    fprintf('Calculating LFP for channel %d of %d', ch, size(ephys,1));
    [~, freqs, t, lfp(:,:,end+1)] = spectrogram(ephys(ch,t_start:t_end), ...
        win_s, win_s - step_s, [], fs_ds, 'yaxis');
end

%% Artifact rejection
thr_amp = 6e5;
pwr_sum = squeeze(sum(lfp,1));
for s = 1:size(lfp,2)
    validCh = pwr_sum(s,:) < thr_amp;
    lfp_mean(:,s) = squeeze(mean(lfp(:,s,validCh),3));
end

artifact = any(lfp_mean == 0,1);
st_art = strel('line',20,90);
artifact = imclose(artifact',st_art)';
