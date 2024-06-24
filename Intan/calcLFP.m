function [lfp_mean,artifact,freqs,t] = calcLFP(data,t_start,t_end,deadEle)

%% Calculate LFP

ephys = data.ephys;
fs = data.params.fs_ephys_ds;
t_start_s = seconds(t_start) * fs; t_end_s = seconds(t_end) * fs;
step_s = 1 * fs; % window steps in 1 second increments
win_s = 5 * fs; % window length is 5 seconds (80% overlap between windows)
lfp = [];

for ch = 1:size(ephys,1)
    if ismember(ch,deadEle)
        continue
    end
    clc
    
    fprintf('Calculating LFP for channel %d of %d', ch, size(ephys,1));
    [~, freqs, t, lfp(:,:,end+1)] = spectrogram(ephys(ch,t_start_s : t_end_s), ...
        win_s, win_s - step_s, [], fs, 'yaxis');
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
