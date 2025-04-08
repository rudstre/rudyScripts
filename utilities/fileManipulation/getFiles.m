function files = getFiles(filtSpec, path)
% GETFILES Get files from a directory matching a filter specification
%   files = GETFILES(filtSpec, path) returns a structure array of files
%   matching the filter specification in the specified path.
%
%   files = GETFILES(filtSpec) prompts the user to select a directory and
%   returns files matching the filter specification.
%
%   files = GETFILES() prompts the user to select a directory and returns
%   all files (no filtering).
%
%   Input arguments:
%   - filtSpec: Regular expression pattern for file extensions (default: '.*')
%   - path: Directory path to search (default: user selected via dialog)
%
%   Output:
%   - files: Structure array of matching files (dir format)

% Handle input arguments
if nargin < 1 || isempty(filtSpec)
    filtSpec = '.*';
end

if nargin < 2 || isempty(path)
    path = uigetdir(pwd, 'Select folder:');
    if path == 0  % User canceled dialog
        files = [];
        return;
    end
end

% Get all files (excluding directories)
dirData = dir(fullfile(path, '*'));
isFile = ~[dirData.isdir];
files = dirData(isFile);

% If no files found or no filtering needed, return
if isempty(files) || strcmp(filtSpec, '.*')
    return;
end

% Apply filter on file extensions
keepIdx = false(1, length(files));
for i = 1:length(files)
    [~, ~, ext] = fileparts(files(i).name);
    % Check if the extension matches the filter
    keepIdx(i) = ~isempty(regexp(ext, filtSpec, 'once'));
end

% Return only the files that matched the filter
files = files(keepIdx);
end