function [delta,normalizedLFP,lfpFrequencies,clusterMode] = calcDelta(pwrSpectrum,frequencies,activePeriods,artifact)
%% Define sizes
fullSpectrumLength = size(pwrSpectrum,2);
noArtifactLength = nnz(~artifact);

%% Compute the normalized frequency distribution
isLFPFrequency = iswithin(frequencies, 1, 9.5);
lfpFrequencies = frequencies(isLFPFrequency);
lfp = pwrSpectrum(isLFPFrequency,:);

normalizedLFP = normalize(lfp,1,'norm');
normalizedLFP_real = normalizedLFP(:,~artifact); % no artifacts

%% Get only parts of LFP that were during inactive periods
activePeriods_real = activePeriods(~artifact); % No artifacts
inactiveLFP = normalizedLFP_real(:,~activePeriods_real); % No artifacts, no movement

%% Find periods of delta in this set
[~,LFP_pca] = pca(inactiveLFP','NumComponents',4);

% Fit 3 component GMM

f = figure;
gcfFullScreen;

numClusts = 6;
clusters = generateClusters(LFP_pca,numClusts);

char_press = 0;
while true
    switch char_press
        case double('=')
            numClusts = numClusts + 1;
            clusters = generateClusters(LFP_pca,numClusts);
        case double('-')
            numClusts = numClusts - 1;
            clusters = generateClusters(LFP_pca,numClusts);
        case double('j')
            [x,~] = ginput(2);
            clustsToJoin = sortedClusters(round(x * 60));
            clusters(clusters == max(clustsToJoin)) = min(clustsToJoin);
        case double('s')
            [x,~] = ginput(1);
            clustToSplit = sortedClusters(round(x * 60));
            clusters = splitCluster(LFP_pca,clusters,clustToSplit);
        case 13 % enter
            break
    end

    %% Plot LFP and clusters

    % Plot LFP
    sortedClusters = plotLFP(inactiveLFP,lfpFrequencies,clusters);

    title(sprintf('done! (%d clusters)', numClusts))
    waitforbuttonpress;
    char_press = double(get(gcf,'CurrentCharacter'));
end

%% User selection of cluster corresponding to delta
hold on
deltaClusts = [];
while true
    [x,~] = ginput(1);
    if isempty(x)
        break
    end
    curClust = sortedClusters(round(x * 60));
    deltaClusts = unique([deltaClusts curClust]);
    current_epoch = [round(find(sortedClusters == curClust, 1, 'first') / 60) round(find(sortedClusters == curClust, 1, 'last') / 60)];
    rectangle('Position', [current_epoch(1), 0, current_epoch(2) - current_epoch(1), curClust], 'FaceColor', [0 0 1 .7])
    drawnow;
end

% close(f)

%% Cut out smaller epochs

% Put these into the larger array that includes movement (these samples are
% in cluster 0)
clusters_full = zeros(noArtifactLength, 1);
clusters_full(~activePeriods_real) = clusters;

clusterCloseRadius = 30;
deltaOpenRadius = 200; % Must be in NREM for at least  3.5 min
artifactCloseRadius = 20;

strl.clusterCloseRadius = strel('line',clusterCloseRadius,90);
strl.deltaOpenRadius = strel('line',deltaOpenRadius,90);
strl.artifactCloseRadius = strel('line',artifactCloseRadius,90);

clusterMode = modefilt(clusters_full, [29 1], 'replicate');
deltaClust_modefilt = ismember(clusterMode, deltaClusts);
deltaClust_postClose = imclose(deltaClust_modefilt, strl.clusterCloseRadius);
deltaClust_postOpen = imopen(deltaClust_postClose,strl.deltaOpenRadius);

% Puts in larger array that includes artifact samples and then closes
% binary so that artifact samples can be included in delta
delta = zeros(fullSpectrumLength, 1);
delta(~artifact) = deltaClust_postOpen;
delta = imclose(delta, strl.artifactCloseRadius);

function clusters = generateClusters(data,numClusts)

title('calculating clusters...')
drawnow;

options.MaxIter = 400;
gmmodel = fitgmdist(data,numClusts,'Options',options);
clusters = cluster(gmmodel,data);

function clusters = splitCluster(data,clusters,clusterToSplit)
indicesOfInterest = find(clusters == clusterToSplit);
dataOfInterest = data(indicesOfInterest,:);

clusters_split = generateClusters(dataOfInterest, 2);

indicesToSplitOff = indicesOfInterest(clusters_split == 2);
indicesToMoveOver = clusters > clusterToSplit;

clusters(indicesToMoveOver) = clusters(indicesToMoveOver) + 1; % Making space
clusters(indicesToSplitOff) = clusterToSplit + 1;


function sortedClusters = plotLFP(lfp,frequencies,clusters)

% Get all the samples from each cluster
[sortedClusters, sortedClusterOrd] = sort(clusters);

% Plot LFP
subplot(3,1,1)

imagesc((1 : size(lfp,2)) / 60, frequencies, ...
    log10(lfp(:,sortedClusterOrd) + eps));
axis xy
ylabel('Frequency (Hz)')
xlabel('Time (min)')
axis tight
ax1 = gca;

colormap jet
clim([-1.5,-.5])

subplot(3,1,[2,3])
plot((1 : size(lfp,2)) / 60, sortedClusters)
axis tight
ax2 = gca;

linkaxes([ax1 ax2],'x');
