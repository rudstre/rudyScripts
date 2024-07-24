function [behavStates_final,normalizedLFP_banded,lfpFrequencies] = calcDelta(lfp_full,lfp_banded,frequencies,activePeriods,artifact)
%% Define sizes
noArtifactLength = nnz(~artifact);

%% Compute the normalized frequency distribution
isLFPFrequency = iswithin(frequencies, 0, 30.5);
lfpFrequencies = frequencies(isLFPFrequency);
lfp_cut = lfp_full(isLFPFrequency,:);
lfp_banded_cut = lfp_banded(isLFPFrequency,:);

normalizedLFP = normalize(lfp_cut,1,'norm');
normalizedLFP_real = normalizedLFP(:,~artifact); % no artifacts

normalizedLFP_banded = normalize(lfp_banded_cut,1,'norm');
normalizedLFP_banded_real = normalizedLFP_banded(:,~artifact); % no artifacts

%% Get only parts of LFP that were during inactive periods
activePeriods_real = activePeriods(~artifact); % No artifacts
inactiveLFP = normalizedLFP_real(:,~activePeriods_real); % No artifacts, no movement
inactiveLFP_banded = normalizedLFP_banded_real(:,~activePeriods_real);

%% Find periods of delta in this set
[~,LFP_pca] = pca(inactiveLFP_banded','NumComponents',3);

% Fit 3 component GMM

f = figure;
gcfFullScreen;

numClusts = 4;
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
    sortedClusters = plotLFP(inactiveLFP_banded,lfpFrequencies,clusters);

    title(sprintf('done! (%d clusters)', numClusts))
    waitforbuttonpress;
    char_press = double(get(gcf,'CurrentCharacter'));
end

%% User selection of cluster corresponding to delta
sleepStates = clusters;

% stateArray = [1 1.5 2 2.5 3];

[x,~] = ginput(3);
clustsOfInterest = sortedClusters(round(x * 60));
indicesOfInterest = ismember(sleepStates,clustsOfInterest);
samplesOfInterest = clusters(indicesOfInterest);
sleepStates(~indicesOfInterest) = nan;
[~,sleepStates(indicesOfInterest)] = ismember(samplesOfInterest,clustsOfInterest);
% sleepStates(indicesOfInterest) = stateArray(rawStates);
close(f)

%% Cut out smaller epochs

% Put these into the larger array that includes movement (these samples are
% in cluster 0)
behavStates = zeros(size(normalizedLFP,2), 1);
behavStates(~activePeriods & ~artifact') = sleepStates;
behavStates(activePeriods) = 0;
behavStates(artifact) = nan;

behavStates = fillmissing(behavStates,"previous");

behavStates_final = modefilt(behavStates, [9 1], 'replicate');


function clusters = generateClusters(data,numClusts)

title('calculating clusters...')
drawnow;

options.MaxIter = 1500;
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
