function file = fileSelector(titleStr, box)
% FILESELECTOR Opens a dialog to select a file and returns the full path.
%
%   file = FILESELECTOR(titleStr, box) displays a file selection dialog with
%   the specified title. The user can select a file, and the function returns
%   the full path to the selected file. If no title is provided, a default 
%   title 'Select a file:' is used. On non-Windows platforms, an additional 
%   dialog box can be displayed as a workaround.
%
%   Inputs:
%     - titleStr: (Optional) A string that specifies the title of the file
%       selection dialog. Defaults to 'Select a file:'.
%     - box: (Optional) A boolean flag indicating whether to show an additional 
%       message box on non-Windows platforms as a workaround. Defaults to true.
%
%   Output:
%     - file: A string containing the full path to the selected file.
%
%   Example:
%     % Prompt the user to select a file with a custom title:
%     selectedFile = fileSelector('Please choose a file to open:');
%
%     % Prompt the user to select a file with the default title and no additional message box:
%     selectedFile = fileSelector('Select a file:', false);

% Check if the 'box' argument is provided; if not, default to true
if nargin < 2
    box = true;
end

% Check if a title string is provided; if not, use the default title
if nargin == 0
    titleStr = 'Select a file:';
end

% Display a workaround message box on non-Windows platforms if 'box' is true
if ~ispc && box
    menu(titleStr, 'OK'); 
end

% Open a file selection dialog and get the selected file and its path
[file, path] = uigetfile('*.*', titleStr);

% Combine the file name and path into a single full file path string
file = fullfile(path, file);

end
