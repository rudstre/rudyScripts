%% Set data to acquire
deadEle = [13:16, 27:29, 31:33, 38,56,64];
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
saveEvery = 10; % save data every x chunks

%% Acquire data
for chk = 1:length(shifts)
    
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
    data.dio = [data.dio; dio];
    
    % save data every x times
    if mod(chk,saveEvery) == 0
        clc
        fprintf('Saving data at shift %d\n',chk)
        data.lastSave = chk;
        save('rhdData_24.mat','data','-v7.3');
    end
    
end