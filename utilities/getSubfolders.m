function [subfolders_paths, subfolders] = getSubfolders(path)
    % Get the paths and names of all subfolders within a specified directory
    %
    % Inputs:
    %   path: Directory path from which to get subfolders (optional, opens dialog if not provided)
    %
    % Outputs:
    %   subfolders_paths: Cell array containing full paths of the subfolders
    %   subfolders: Structure array containing details of the subfolders

    % If no path is provided, open a dialog to select a directory
    if nargin == 0
        path = uigetdir;
    end

    % Get directory information for the specified path
    d = dir(path);

    % Filter out only directories, excluding '.' and '..'
    subfolders = d([d(:).isdir]);
    subfolders = subfolders(~ismember({subfolders(:).name}, {'.', '..'}));

    % Create full paths for each subfolder
    subfolders_paths = fullfile(subfolders(1).folder, {subfolders.name})';
end
