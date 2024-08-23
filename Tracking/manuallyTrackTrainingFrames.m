function datasets = manuallyTrackTrainingFrames(fr_path, resumeSession)
% MANUALLYTRACKTRAININGFRAMES Manually track objects in sample frames to
% train DeeperCut model
% Ashesh Dhawale 2018
% INPUTS:
% fr_path: Path to the folder with images to be used as a training set.
% e.g. '//.../ratname/data/'
% resumeSession: 1 if you want to resume from the last save point.
if nargin < 2
    resumeSession = 0;
end

%% Define datasets

img_id_labels = {'R_','L_','top_'};  % dataset specific prefixes if images from different datasets (e.g. left and right cameras) are in the same folder. Can be empty string too.
ext = '.png'; % for image files

%% Define objects, their colors and associated keypresses here

%       #       name        color       keypress
% objs =  {
%         0,      'L_paw',    [.8,.2,.2], double('1');
%         1,      'R_paw',    [1,0,1],    double('2');
%         2,      'nose',     [0,0,1],    double('3');
%         3,      'eye',      [0,1,0],    double('4');
%         4,      'ear',      [0,1,1],    double('5');
% %         5,      'back',     [1,1,0],    double('6');
% %         6,      'implant',  [.2,.2,.8], double('7');
%         };

objs1 =  {
    0,      'paw1',    [.8,.2,.2], double('1');
    1,      'nose',    [1,0,1],    double('2');
    2,      'eye',     [0,0,1],    double('3');
    3,      'ear',      [0,1,0],    double('4');
    4,      'back',      [0,1,1],    double('5');
    5,      'elbow1',     [1,1,0],    double('6');
    6,      'paw2',  [.2,.2,.8], double('7');
    %         7,      'implant',  [.2,.8,.2], double('8');
    };

objs2 =  {
    0,      'nose',    [.8,.2,.2], double('1');
    1,      'eyeL',    [1,0,1],    double('2');
    2,      'eyeR',     [0,0,1],    double('3');
    3,      'pawL',    [0,1,1],    double('4');
    4,      'pawR',     [1,1,0],    double('5');
    %         3,      'implant',      [0,1,0],    double('6');
    };

objs1 = struct( 'num', objs1(:,1), 'name', objs1(:,2), 'color', objs1(:,3), 'keypress', objs1(:,4));
objs2 = struct( 'num', objs2(:,1), 'name', objs2(:,2), 'color', objs2(:,3), 'keypress', objs2(:,4));

generic_key = 1; % mouse left button press to cycle through objects

%% Define action-keystrokes here
delete_last_key = double('d');
get_current_key = double('q');
skip_current_key = double('w');
ignore_frame_key = double('x'); % to remove current frame from training dataset (set keep = 0)
clear_frame_key = double('c'); % to clear markers from current frame
previous_frame_key = double(',<'); % to go back one frame
next_frame_key = double('.>'); % to go forward one frame
first_frame_key = double('a'); % skip to first frame
last_frame_key = double('z'); % skip to last frame
keep_frame_key = double(' '); % spacebar to keep current frame and load next frame (keep = 1)
end_session_key = 27; % Hit escape key to end session and save dataset as is. Also needs to be executed at the end of labeling.
up_gain_key = double('+='); % increase display gain
down_gain_key = double('-'); % decrease display gain

%% Manually track frames

h = figure('Position', [500, 100, 700, 850]); % labeling figure window

if ~any(strcmp({'\', '/'}, fr_path(end)))
    fr_path = [fr_path '/'];
end % fix errors in the path if any

datasets = cell(length(img_id_labels),1); % dataset container

for lr = 1 : 3 % loop over all cameras

    if lr<3
        objs = objs1;
    else
        objs = objs2;
    end

    if exist([fr_path img_id_labels{lr} 'dataset.mat'], 'file')==2 % dataset already exists
        whatToDo = questdlg([img_id_labels{lr} ' dataset exists!'], 'Warning!','Skip', 'Review', 'Restart','Skip');
    elseif resumeSession && exist([fr_path img_id_labels{lr} 'dsetobjs.mat'], 'file')==2 % autosaved data exists
        whatToDo = 'Resume';
    else
        whatToDo = 'Restart';
    end

    if ~strcmp(whatToDo, 'Skip')

        % list of images for this dataset
        frlist = dir([fr_path img_id_labels{lr} '*' ext]);
        [~,i] = sort([frlist.datenum]);
        frlist = frlist(i); % sort by date modified
        frlist = {frlist.name};

        switch whatToDo
            case 'Restart' % start from scratch
                dsetobjs = struct('image',[],'size',[],'joints',[],'keep',[]);
                dsetobjs(length(frlist)).keep = []; % define its length
                fr_count = 1; % frame counter

            case 'Resume' % load from autosave and start after last marked frame
                load([fr_path img_id_labels{lr} 'dsetobjs.mat'], 'dsetobjs');
                fr_count = find(~cellfun(@isempty, {dsetobjs.keep}),1,'last')+1; % start after last tracked image

            case 'Review' % load from dataset and start from first marked frame
                load([fr_path img_id_labels{lr} 'dataset.mat'], 'dataset');
                dsetobjs = struct('image',[],'size',[],'joints',[],'keep',[]);
                dsetobjs(length(frlist)).keep = []; % define its length
                fr_counts = [];
                for fr = 1 : length(frlist)
                    % check if this frame exists in dataset
                    frind = find(~cellfun(@isempty, strfind({dataset.image}, frlist{fr})),1);
                    if ~isempty(frind)
                        dsetobjs(fr).image = dataset(frind).image;
                        dsetobjs(fr).size = dataset(frind).size;
                        dsetobjs(fr).joints = dataset(frind).joints;
                        dsetobjs(fr).keep = 1;
                        fr_counts(end+1) = fr;
                    else
                        % else assume it is not worth keeping
                        dsetobjs(fr).image = ['../data/' frlist{fr}];
                        img = imread([fr_path '/' frlist{fr}]);
                        dsetobjs(fr).size = permute(size(img), [3,1,2]);
                        dsetobjs(fr).joints{1} = [];
                        dsetobjs(fr).keep = 0;
                        %fr_count = fr;
                    end
                end
                fr_count = fr_counts(find(diff(fr_counts) ~= 1,1,'first')) + 1;
                %                 fr_count = 1; % start from first frame
        end

        sess_stop_input = 0; % to terminate labeling
        disp_gain = 1;
        while fr_count <= length(frlist) && ~sess_stop_input

            % Load image
            img = imread([fr_path '/' frlist{fr_count}]);

            figure(h);
            clf;
            image(img.*disp_gain); % plot current frame
            axis image;

            % construct title/legend
            title_string = ['\fontsize{14} Frame ' num2str(fr_count) '   '];
            for o = 1 : length(objs)
                title_string = [title_string '{\color[rgb]{' num2str(objs(o).color) '}' objs(o).name '}:' char(objs(o).keypress) '  '];
            end
            title(title_string);
            hold on;

            fr_objs = objs; % struct to store object positions and plot handles on current frame
            fr_objs(1).pos = []; fr_objs(1).handle = [];
            if ~isempty(dsetobjs(fr_count).keep) && ~isempty(dsetobjs(fr_count).joints)
                for o = 1 : size(dsetobjs(fr_count).joints{1},1)
                    oind = [objs.num] == dsetobjs(fr_count).joints{1}(o,1);
                    fr_objs(oind).pos = dsetobjs(fr_count).joints{1}(o,2:3);
                    fr_objs(oind).handle = plot(fr_objs(oind).pos(1), fr_objs(oind).pos(2), '*', 'Color', fr_objs(oind).color, 'markersize', 10);
                end
            end

            % Frame label color indicates keep status
            if isempty(dsetobjs(fr_count).keep)
                lab_col = [0,0,0];
            elseif dsetobjs(fr_count).keep
                lab_col = [1,0,0];
            else
                lab_col = [.7,.7,.7];
            end
            xlabel(['\fontsize{14}\color[rgb]{' num2str(lab_col) '}' strrep(frlist{fr_count}, '_', '\_')]); % color highlights keep status of the frame

            % process input loop
            stop_input = 0; keep = []; sess_stop_input = 0; incr = 0; curr_obj = 1;
            while ~stop_input
                [x,y,butn] = ginput(1); % get user button-press and mouse position input

                if ~isempty(butn)
                    switch butn
                        case {objs.keypress} % key-specific object has been marked
                            fr_objs([objs.keypress] == butn).pos = [x,y]; % record object position

                            % Re-plot all marked objects
                            for i = 1 : length(fr_objs)
                                if ~isempty(fr_objs(i).pos)
                                    if ~isempty(fr_objs(i).handle)
                                        delete(fr_objs(i).handle);
                                    end
                                    fr_objs(i).handle = plot(fr_objs(i).pos(1), fr_objs(i).pos(2), '*', 'Color', fr_objs(i).color, 'markersize', 10);
                                end
                            end

                        case {generic_key} % current object has been marked
                            fr_objs(curr_obj).pos = [x,y];

                            % Re-plot all marked objects
                            for i = 1 : length(fr_objs)
                                if ~isempty(fr_objs(i).pos)
                                    if ~isempty(fr_objs(i).handle)
                                        delete(fr_objs(i).handle);
                                    end
                                    fr_objs(i).handle = plot(fr_objs(i).pos(1), fr_objs(i).pos(2), '*', 'Color', fr_objs(i).color, 'markersize', 10);
                                end
                            end

                            % update current object
                            if curr_obj < length(objs)
                                curr_obj = curr_obj+1;
                            else
                                curr_obj = 1;
                            end

                        case num2cell(get_current_key)
                            fr_objs(curr_obj).pos = [x,y];

                            % Re-plot all marked objects
                            for i = 1 : length(fr_objs)
                                if ~isempty(fr_objs(i).pos)
                                    if ~isempty(fr_objs(i).handle)
                                        delete(fr_objs(i).handle);
                                    end
                                    fr_objs(i).handle = plot(fr_objs(i).pos(1), fr_objs(i).pos(2), '*', 'Color', fr_objs(i).color, 'markersize', 10);
                                end
                            end

                            % update current object
                            if curr_obj < length(objs)
                                curr_obj = curr_obj+1;
                            else
                                curr_obj = 1;
                            end

                        case num2cell(delete_last_key)
                            if curr_obj>1
                                curr_obj = curr_obj-1;
                                fr_objs(curr_obj).pos = [];
                                delete(fr_objs(curr_obj).handle);

                                % Re-plot all marked objects
                                for i = 1 : length(fr_objs)
                                    if ~isempty(fr_objs(i).pos)
                                        if ~isempty(fr_objs(i).handle)
                                            delete(fr_objs(i).handle);
                                        end
                                        fr_objs(i).handle = plot(fr_objs(i).pos(1), fr_objs(i).pos(2), '*', 'Color', fr_objs(i).color, 'markersize', 10);
                                    end
                                end
                            else
                                curr_obj = 1;
                            end

                        case num2cell(skip_current_key)

                            % update current object
                            if curr_obj < length(objs)
                                curr_obj = curr_obj+1;
                            else
                                curr_obj = 1;
                            end

                        case num2cell(clear_frame_key) % clear marked objects
                            for i = 1 : length(fr_objs)
                                fr_objs(i).pos = [];
                                delete(fr_objs(i).handle);
                                fr_objs(i).handle = [];
                            end

                            curr_obj = 1;

                        case num2cell(ignore_frame_key) % remove frame from dataset
                            keep = 0;
                            stop_input = 1;
                            xlabel(['\fontsize{14}\color[rgb]{' num2str([.7,.7,.7]) '}' strrep(frlist{fr_count}, '_', '\_')]); % color highlights keep status of the frame
                            incr = 1;

                        case num2cell(keep_frame_key) % keep current frame and go to next frame
                            keep = 1;
                            stop_input = 1;
                            xlabel(['\fontsize{14}\color[rgb]{' num2str([1,0,0]) '}' strrep(frlist{fr_count}, '_', '\_')]); % color highlights keep status of the frame
                            incr = 1;

                        case num2cell(next_frame_key) % go forward one frame
                            keep = [];
                            stop_input = 1;
                            incr = 1;

                        case num2cell(previous_frame_key) % go back one frame
                            keep = [];
                            stop_input = 1;
                            incr = -1;

                        case num2cell(first_frame_key) % go to 1st frame
                            keep = [];
                            stop_input = 1;
                            incr = -Inf;

                        case num2cell(last_frame_key) % go to last frame
                            keep = [];
                            stop_input = 1;
                            incr = Inf;

                        case num2cell(end_session_key) % end this session and save results
                            keep = [];
                            stop_input = 1;
                            sess_stop_input = 1;

                        case num2cell(up_gain_key) % increase display gain
                            keep = [];
                            stop_input = 1;
                            disp_gain = disp_gain * 2;

                        case num2cell(down_gain_key) % increase display gain
                            keep = [];
                            stop_input = 1;
                            disp_gain = disp_gain / 2;
                    end
                end
            end


            if ~isempty(keep) % user has made a decision to keep or discard a frame
                dsetobjs(fr_count).keep = keep;
                if keep
                    dsetobjs(fr_count).image = ['../data/' frlist{fr_count}];
                    dsetobjs(fr_count).size = size(img);
                    dsetobjs(fr_count).size = dsetobjs(fr_count).size([3,1,2]);
                    fr_obj_ind = ~cellfun(@isempty, {fr_objs.pos});
                    dsetobjs(fr_count).joints{1} = [vertcat(fr_objs(fr_obj_ind).num), vertcat(fr_objs(fr_obj_ind).pos)];
                    if isempty(dsetobjs(fr_count).joints{1})
                        dsetobjs(fr_count).joints{1} = zeros(0,3);
                    end
                end
            end
            fr_count = fr_count + incr;
            fr_count = max([1, fr_count]);
            fr_count = min([length(frlist), fr_count]);

            % autosave dataset on every frame
            save([fr_path img_id_labels{lr} 'dsetobjs.mat'], 'dsetobjs');
        end
        dataset = dsetobjs(cellfun(@(x) ~isempty(x) && x==1, {dsetobjs.keep})); % compile final dataset
        dataset = rmfield(dataset, 'keep');
        save([fr_path img_id_labels{lr} 'dataset.mat'], 'dataset'); % save final version
        delete([fr_path img_id_labels{lr} 'dsetobjs.mat']); % delete autosaved version

    else % skip
        load([fr_path img_id_labels{lr} 'dataset.mat'], 'dataset'); % load final dataset
    end

    datasets{lr} = dataset;
end

close(h);
end

