function [act_final, acc_smooth] = getActivePeriods(accData,thr)

%% Find movement epochs using accelerometer data
if nargin < 2
    thr = 6e-7;
end

st_acc = strel('line',60,90);
acc_smooth = movmean(accData,20,'omitnan');

act = acc_smooth > thr;
act_open = imopen(act,st_acc);
act_final = imclose(act_open,st_acc);