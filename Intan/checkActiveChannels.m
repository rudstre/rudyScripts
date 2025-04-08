function checkActiveChannels(path)
% CHECKACTIVECHANNELS Verify consistent active channels across RHD2000 files
%   This function checks if all RHD2000 files in a directory have the same
%   active channels configured.

% Handle input arguments
if nargin < 1 || isempty(path)
    path = uigetdir(pwd, 'Select directory with RHD2000 data files');
    if path == 0
        return;
    end
end

% Get all RHD files in the directory
files = getFiles('rhd$', path);
if isempty(files)
    error('No RHD2000 files found in the specified directory.');
end

fnames = {files.name};
fprintf('Found %d RHD2000 files to check.\n', length(fnames));

% Read the first file and store the amplifier_channels variable
template_channels = readIntanChannelNames(fullfile(path, fnames{1}));
templChNames{1} = cellfun(@(x) str2double(x(3:end)), template_channels);
group_ids = 1;
group_idxs = 1;

% Compare each file against the template
for f = 2:length(fnames)
    fprintf('Checking file %d of %d: %s\n', f, length(fnames), fnames{f});

    % Read the current file
    current_channels = readIntanChannelNames(fullfile(path, fnames{f}));
    curChNames = cellfun(@(x) str2double(x(3:end)), current_channels);

    % Compare with template
    if length(curChNames) == length(templChNames{end}) && ...
            all(curChNames == templChNames{end})
        continue
    end

    match = false;
    for t = (length(templChNames) - 1) : -1 : 1
        if length(curChNames) == length(templChNames{t}) && all(curChNames == templChNames{t})
            grp = t;
            match = true;
            break
        end
    end

    group_idxs(end+1) = f;

    % No match found; new group
    if ~match
        group_ids(end+1) = length(templChNames) + 1;
        templChNames{end + 1} = curChNames;
        fprintf('New active channel group %d starts with %s\n', ...
            group_ids(end), group_idxs(end));
    
    % Match found to old group
    else
        group_ids(end + 1) = grp;
        group_id(end + 1) = f;
        fprintf('Active channel group switches back to group %d at %s\n',...
            group_ids(end), fnames{group_idxs(end)})
    end
end

clc
fprintf('%d different blocks found.\n',length(group_idxs))
for g = 1:length(group_idxs)
    fprintf('Group %d starts with %s\n',g,fnames{group_idxs(g)});
end