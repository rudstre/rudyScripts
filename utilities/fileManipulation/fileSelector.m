function file = fileSelector()
[file,path] = uigetfile('*.*');
file = fullfile(path,file);