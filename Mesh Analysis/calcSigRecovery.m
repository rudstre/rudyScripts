fc_acc = [395 415];
fs_acc = 20000;
[b_acc, a_acc] = butter(2, fc_acc / (fs_acc / 2), 'bandpass'); % 4th order
dat_filt = filter(b_acc ,a_acc, data,[],2);
ma = movmax(dat_filt,.5*20000,2);
mi = movmin(dat_filt,.5*20000,2);
pp = ma-mi;
rec = pp/500;
rec = mean(rec,2);

titlt

pr = [];
for i = 0:15:2000
    idxs = iswithin(imp2(gi2)/1e3,i-50,i+50);
    gs = gi_still(idxs);
    pr(end+1) = mean(gs);
end

