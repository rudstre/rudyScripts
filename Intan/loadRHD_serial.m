%% User params
acq_start = duration(19,0,0); % start acquisition at this time (hours,minutes,seconds)
acq_len = duration(4,0,0); % total length to acquire in hours,minutes,seconds

fs_ephys = 30000; %30kHz
fs_acc = 300;

deadEle = [2, 3, 13:16, 27:29, 31:33, 38, 56, 64];

%% Compute data to acquire
[file,path] = uigetfile('Z:\Lab\forRudy\*.rhd','Select RHD file of interest:');
[~,n] = fileparts(fullfile(path,file));

file_start_date = tick2datetime(str2double(n));
file_start_time = timeofday(file_start_date);

acq_offset = acq_start - file_start_time; % in hours
acq_offset_s = seconds(acq_offset) * fs_ephys; % converts to sample offset
   
read_length = seconds(acq_len); % duration in seconds
read_length_s = read_length * fs_ephys; % in samples

chunkSize = duration(0,4,0); % read in 4 minute chunks
chunkSize_s = seconds(chunkSize) * fs_ephys; % convert to sample length

read_end = read_length_s - chunkSize_s; % calculate offsets for each chunk

shifts = 0 : chunkSize_s : read_end; % calculate offsets for each chunk

if shifts(end) ~= read_end
    shifts(end+1) = read_end;
end

shifts = shifts + acq_offset_s; % add in the constant offset to start at the right time

params = struct('acq_offset_s',acq_offset_s,'acq_offset_e',acq_offset_s + read_length_s,...
        'fs_ephys',fs_ephys,'fs_ephys_ds',fs_ephys/100,'fs_acc',fs_acc,'filename',n);

%% Initialize structs
if exist('data','var') && ~isequal(data.params, params)
    error('Params do not match existing struct!')
elseif ~exist('data','var')
    data = struct('acc',[],'ephys',[],'dio',[],'lastSave',0);
    data.params = params;
end

acc = [];
ephys = [];
dio = [];

t = 60; % initial guess for time to acquire chunk
saveEvery = 10; % save data every x chunks

%% Acquire data
for chk = data.lastSave + 1 : length(shifts)
    
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
        save('rhdData_early.mat','data','-v7.3');
    end
    
end

clc
fprintf('Saving final data \n')
data.lastSave = chk;
save('rhdData_early.mat','data','-v7.3');