% example loading of the first 1 minute of the file (60 = 60 seconds, 30K =
% number of samples per second)


[name,path] = uigetfile('*.*');
filename = fullfile(path,name);
fid = fopen(filename);

[ephys, acc, vdd, tmp, dio] = readRHD_oldFormat(fid, -1, 60*30000, 64);
fclose(fid);