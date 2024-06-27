%% Get all paths for the various models
[method_paths,method_dirs] = getSubfolders;
path_all_runs = cellfun(@getSubfolders,method_paths,'uni',false);

selectedMethods = listdlg('PromptString','Select methods to compare:',...
    'ListString',{method_dirs.name});

path_all_runs = path_all_runs(selectedMethods);

nmethods = size(path_all_runs,1);
nruns = size(path_all_runs{1},1);

%% Fetch all PPSeq models
eventTimes = cell(nmethods,nruns);
for method = 1:nmethods
    for run = 1:nruns
        ppseq = importPPSeqModel(path_all_runs{method}{run});
        evnts = ppseq.events;
        eventTimes{method,run} = [evnts.ts, evnts.type];
    end
end

%% Convolve individual detections with gaussian kernel and 
% compute mean squared divergence

% Generate kernel
t = -6:.1:6;
gauss = normpdf(t,0,1);

% Generate combinations of methods and runs to test
combos_r = nchoosek(1:nruns,2);
combos_m = [ones(nmethods,2) .* (1:nmethods)'; nchoosek(1:nmethods,2)];

% Initialize difference cell
dif = zeros(size(combos_m,1),size(combos_r,1));

% Iterate through all method combinations
for method = 1:size(combos_m,1)

    % Iterate through all run combinations
    for run = 1:size(combos_r,1)

        % Get events detected for the current two to be compared
        ts1 = eventTimes{combos_m(method,1), combos_r(run,1)};
        ts2 = eventTimes{combos_m(method,2), combos_r(run,2)};

        for seq = unique(ts2(:,2))'

            % Skip background event
            if seq == -1, continue, end

            % Get only events of current sequence
            rightSeq1 = ts1(:,2) == seq;
            rightSeq2 = ts2(:,2) == seq;
            ts1_seq = ts1(rightSeq1, 1);
            ts2_seq = ts2(rightSeq2, 1);

            % Compute a binned time vector for the event detections
            [ts1_vec,bins] = histcounts(ts1_seq,'BinWidth',.1);
            ts2_vec = histcounts(ts2_seq,bins);

            % Convolve with gaussian kernel
            conv_1 = conv(ts1_vec, gauss, 'same');
            conv_2 = conv(ts2_vec, gauss, 'same');

            % Compute squared difference
            dif(method,run) = dif(method,run) + sum((conv_1 - conv_2).^2);
        end
    end
end

%% Compute overall metrics and plot

% Calculate mean and standard error
dif_avg = mean(dif,2);
dif_stderr = std(dif,[],2) / sqrt(size(dif,2));

% Create cell of names
nameCell = {};
for comb = combos_m'
    part1 = escapeString(method_dirs(comb(1)).name);
    part2 = escapeString(method_dirs(comb(2)).name);
    if strcmp(part1,part2)
        nameCell{end+1} = part1;
    else
        nameCell{end+1} = sprintf('%s : %s', part1, part2);
    end
end

% Plot bar graph and error bars
figure();
bar(nameCell,dif_avg)
hold on
er = errorbar(dif_avg,dif_stderr,'LineWidth',1.5);
er.Color = [0 0 0];
er.LineStyle = 'none';

% Format figure
title('Comparing event detection variability within and between methods')
set(gca,'FontSize',18)
ylabel('Mean squared divergence')
