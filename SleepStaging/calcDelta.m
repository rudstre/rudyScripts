function [delta,lfp_norm,freqs_oi] = calcDelta(lfp,freqs,acc_bin,artifact)

%% Compute the normalized frequency distribution
freq_idxs = iswithin(freqs,1,10);
freqs_oi = freqs(freq_idxs);

pwr_reduced = lfp(freq_idxs,:);
lfp_norm = normalize(pwr_reduced,1,'norm');
lfp_norm2 = lfp_norm(:,~artifact);

%% Find the periods of delta
rad = 60;
st = strel('line',rad,90);
st_open = strel('line',300,90);

act_matched = acc_bin(1:length(artifact));
acc_reduced = act_matched(~artifact);

lfp_still = lfp_norm2(:,~acc_reduced);
[~,s] = pca(lfp_still','NumComponents',30);
options.MaxIter = 400;
gmmodel = fitgmdist(s,5,'Options',options);
clusts = cluster(gmmodel,s);
[vals,ord] = sort(clusts);

f = figure;
gcfFullScreen;
subplot(3,1,1)
imagesc((1:length(lfp_still))/60, freqs_oi, log10(lfp_still(:,ord) + eps));
hold on;
axis xy
ylabel('Frequency (Hz)')
xlabel('Time (min)')
axis tight
ylim([1 max(freqs_oi)])
colormap jet
caxis([0 2])
caxis([-3,-.5])

subplot(3,1,[2,3])
plot((1:length(vals))/60,vals)
axis tight

subplot(3,1,1)
[x,~] = ginput(1);
deltaClust = vals(round(x*60));
close(f)

cl = zeros(size(lfp_norm2,2),1);
cl(~acc_reduced) = clusts;

delta_bin = modefilt(cl,[29 1]) == deltaClust;
delta_cl = imclose(delta_bin,st);
delta_final = imopen(delta_cl,st_open);

st_art = strel('line',20,90);
delta = zeros(size(lfp,2),1); 
delta(~artifact) = delta_final;
delta = imclose(delta,st_art);