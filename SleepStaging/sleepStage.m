function selected_epochs = sleepStage(rhdData,ustruct,t_start,t_end,unit_list)

%% Get LFP
deadEle = [13:16, 27:29, 31:33, 38,56,64];
[lfp,artifact,freqs,t] = calcLFP(rhdData.ephys,t_start,t_end,deadEle);

%% Get accelerometer data
ts_acc = t_start/300; te_acc = t_end/300;
acc_all = rhdData.acc(ts_acc:te_acc,2);

[acc_bin, acc_smooth] = getActivePeriods(acc_all);

%% Get periods of delta
[delta_final,lfp_norm,freqs_oi] = calcDelta(lfp,freqs,acc_bin,artifact);

%% Plot LFP
subplot(3,1,1)
imagesc(t/60, freqs_oi, log10(lfp_norm + eps))

hold on;
axis xy
ylabel('Frequency (Hz)')
xlabel('Time (min)')
axis tight
ylim([1 10])
colormap jet
% caxis([0 2])
caxis([-3,-.5])
ax1 = gca;

%% Plot delta binary
subplot(3,1,2)
plot(t/60,delta_final)
ylim([0,2])
ax2 = gca;


%% Plot movement periods
subplot(3,1,3)
plot((1:length(acc_bin))/60,acc_bin)
hold on
plot((1:length(acc_bin))/60,acc_smooth/max(acc_smooth))
ax3 = gca;


%% Link axes
linkaxes([ax1,ax2,ax3],'x')
axis tight

%% User-selection of delta epochs to export
epochs_linear = find(diff(delta_final))/60;
epochs = zeros(length(epochs_linear)/2,2);
if delta_final(1)
    epochs(2:end,1) = epochs_linear(2:2:end);
    epochs(:,2) = epochs_linear(1:2:end);
else
    epochs(:,1) = epochs_linear(1:2:end);
    epochs(:,2) = epochs_linear(2:2:end);
end

subplot(3,1,2)
epoch_nums = [];
selected_epochs = [];
cols = distinguishable_colors(size(epochs,1));
cnt = 0;
while true
    cnt = cnt + 1;
    [x,~] = ginput(1);
    if isempty(x)
        break
    end
    [~,current_enum] = find(iswithin(x,epochs'));
    current_epoch = epochs(current_enum,:);
    if ~isempty(current_epoch)
        epoch_nums(end+1) = current_enum;
        selected_epochs(end+1,:) = current_epoch;
        rectangle('Position',[current_epoch(1),0,current_epoch(2)-current_epoch(1),1],'FaceColor',[cols(cnt,:) .7])
        drawnow;
    end
end

selected_epochs_sec = double(selected_epochs) * 60;
selected_time = diff(selected_epochs,[],2);
tot_time = sum(selected_time);

%% Save selected epochs to disk
[fname,path] = uiputfile('*.txt','Select save location',...
    '/Users/rudygelb-bicknell/Documents/PPSeq_fork.jl/demo/data/');
fp = fullfile(path,fname);

end_time = -.5;
for i = 1:size(selected_epochs,1)
    end_time = saveRHDEpochToFile(ustruct,'637181493672024509',...
        selected_epochs_sec(i,1) * 30000, selected_epochs_sec(i,2) * 30000, end_time + .5, fp, unit_list);
end

clc
fprintf('Done! %.1f minutes of data from %d delta epochs saved to disk at %s.\n', ...
    tot_time, size(selected_epochs,1), fp);

