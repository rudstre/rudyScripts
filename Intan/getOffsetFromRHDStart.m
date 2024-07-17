function [offset,rhdID] = getOffsetFromRHDStart(start_time,rhdID)

if nargin < 2 || isempty(rhdID)
    [file,path] = uigetfile('Z:\Lab\forRudy\*.rhd','Select RHD file of interest:');
    filename = fullfile(path,file);
    [~,rhdID] = fileparts(filename);
end

file_start_date = tick2datetime(str2double(rhdID));

offset = start_time - file_start_date;