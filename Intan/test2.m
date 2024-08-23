t_read = 600; % in seconds
chunkSize = 60;
shifts = 0:chunkSize:t_read-chunkSize; shifts(1) = -1;

[name,path] = uigetfile('*.*');
filename = fullfile(path,name);

for i = 1:length(shifts)
    clc
    fprintf('Loading chunk %d of %d\n',i,length(shifts))
    [acc_filt,ephys_dec] = readRHDandDownsample(filename,shifts(i),chunkSize);
    acc
end