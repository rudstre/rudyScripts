function [subfolders_paths,subfolders] = getSubfolders(path)

if nargin == 0
    path = uigetdir;
end

d = dir(path);

subfolders = d([d(:).isdir]);
subfolders = subfolders(~ismember({subfolders(:).name},{'.','..'}));

subfolders_paths = fullfile(subfolders(1).folder,{subfolders.name})';