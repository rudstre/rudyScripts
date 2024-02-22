fs = 30000;

t_start = 24; % starts at midnight
t_len = 4; % ends at 4am

read_length = t_len * 3600; % duration in seconds 
t_offset = t_start - 14; % file starts at ~14:00
offset = t_offset * fs * 3600; % converts to sample offset

read_length_s = read_length*fs; % in samples

chunkSize = 60; 
chunkSize_s = chunkSize*fs;

shifts = 0:chunkSize_s:read_length_s-chunkSize_s; shifts(1) = -1;
shifts = shifts + offset;

% [name,path] = uigetfile('*.*');
% filename = fullfile(path,name);

filename = '/Volumes/olveczky_lab/Lab/forRudy/637181493672024509.rhd';

acc_pow = [];
ephys = [];
t = 60; % guess for time to acquire chunk
saveEvery = 5;
for i = 1:length(shifts)
    clc
    fprintf('Loading chunk %d of %d. \nEstimated time remaining: %.1f minutes',...
        i, length(shifts), mean(t) * (length(shifts) - i + 1) / 60)
    tic
    [pow,ephys_dec] = readRHDandDownsample(filename,shifts(i),chunkSize_s);
    t(i) = toc;
    data.acc_pow = [data.acc_pow;pow];
    data.ephys = [data.ephys, ephys_dec];
    if mod(i,saveEvery) == 0
        clc
        fprintf('Saving data at shift %d\n',i)
        data.lastSave = i;
        save('rhdData.mat','data');
    end
end

