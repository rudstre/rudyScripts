%% Set data to acquire

fs = 30000; %30kHz

t_start = 18; % start acquisition at this time (18:00 hours)
t_len = 24; % total length to acquire in hours

t_offset = t_start - 14; % file starts at ~14:00
offset = t_offset * fs * 3600; % converts to sample offset

read_length = t_len * 3600; % duration in seconds
read_length_s = read_length * fs; % in samples

chunkSize = 240; % read in 4 minute chunks
chunkSize_s = chunkSize * fs; % convert to sample length

shifts = 0 : chunkSize_s : read_length_s-chunkSize_s; % calculate offsets for each chunk
shifts = shifts + offset; % add in the constant offset to start at the right time

filename = 'Z:\Lab\forRudy\637181493672024509.rhd';

if ~exist('data','var')
    data = struct('acc',[],'ephys',[],'dio',[]);
end

acc = [];
ephys = [];
dio = [];

t = 70; % initial guess for time to acquire chunk
saveEvery = 5; % save data every x chunks

%% Acquire data
for chk = 16:length(shifts)
    
    % print out how far we are
    clc
    fprintf('Loading chunk %d of %d. \nEstimated time remaining: %.1f minutes',...
        chk, length(shifts), mean(t(t~=0)) * (length(shifts) - chk + 1) / 60)
    
    % collect current chunk
    tic
    [acc,ephys,dio] = readRHDandDownsample(filename,shifts(chk),chunkSize_s);
    t(chk) = toc;
    
    % concatenate new chunk and old data
    data.acc = [data.acc; acc];
    data.ephys = [data.ephys, ephys];
    data.dio = [data.dio, dio];
    
    % save data every x times
    if mod(chk,saveEvery) == 0
        clc
        fprintf('Saving data at shift %d\n',chk)
        data.lastSave = chk;
        save('rhdData_24.mat','data','-v7.3');
    end
    
end

%% Calculate LFP

fs_ds = fs/100; % downsampled sampling rate is fs/100
step_s = 1 * fs_ds; % window steps in 1 second increments
win_s = 5 * fs_ds; % window length is 5 seconds (80% overlap between windows)

for ch = 1:size(data.ephys,1)
    clc
    fprintf('Calculating LFP for channel %d of %d', ch, size(data.ephys,1));
    [~, freqs, t, pwr(:,:,ch)] = spectrogram(data.ephys(ch,:), ...
        win_s, win_s - step_s, [], fs_ds, 'yaxis');
end

pwr_mean = squeeze(mean(pwr,3));

%% Exact plotting code from new RHD matlab script
imagesc(t/60, freqs, log10(pwr_mean + eps))
 
hold on;
axis xy
ylabel('Frequency (Hz)')
xlabel('Time (min)')
h = colorbar;
h.Label.String = 'Log(Power)';
axis tight
ylim([.5 55])
caxis([0 1.5])