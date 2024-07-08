uiopen('load');
skeleton = joint_names(joints_idx);
[file,path] = uiputfile('*.h5'); filepath = fullfile(path,file);

% Write bodypart names to the HDF5 file
h5create(filepath, '/node_names', [1, numel(joint_names)], 'Datatype', 'string');
h5write(filepath, '/node_names', joint_names);

% Write edges to the HDF5 file
h5create(filepath, '/edge_names', size(skeleton), 'Datatype', 'string');
h5write(filepath, '/edge_names', skeleton);

fprintf('skeleton written to ''%s''.\n',filepath)
