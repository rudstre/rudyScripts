function [act_final, acc_smooth] = getActivePeriods(rhdData,startTime,endTime,thr)

%% Find movement epochs using accelerometer data
if nargin < 4
    thr = 6e-7;
end

startSample = seconds(startTime) * rhdData.params.fs_acc_downsampled + 1;
endSample = seconds(endTime) * rhdData.params.fs_acc_downsampled;

accData = rhdData.acc(startSample:endSample, 2);

st_acc = strel('line',60,90);
acc_smooth = movmean(accData,20,'omitnan');

act = acc_smooth > thr;
act_open = imopen(act,st_acc);
act_final = imclose(act_open,st_acc);