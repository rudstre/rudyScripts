function [finalBehavStates, normalizedLFPBanded, lfpFrequencies] = calcDelta(lfpFull, lfpBanded, frequencies, activePeriods, artifact)
    % calcDelta - Calculates sleep states based on LFP and activity data
    %
    % Inputs:
    %   lfpFull: Full LFP data matrix
    %   lfpBanded: Banded LFP data matrix (filtered for specific bands)
    %   frequencies: Frequency values corresponding to the LFP data
    %   activePeriods: Binary vector indicating active periods
    %   artifact: Binary vector indicating artifacts in the data
    %
    % Outputs:
    %   finalBehavStates: Final behavioral states with artifacts and active periods accounted for
    %   normalizedLFPBanded: Normalized LFP data within a specific frequency band
    %   lfpFrequencies: Frequencies corresponding to the normalized LFP data

    %% Compute the normalized frequency distribution
    isLFPFrequency = iswithin(frequencies, 0, 30.5);
    lfpFrequencies = frequencies(isLFPFrequency);
    lfpCut = lfpFull(isLFPFrequency, :);
    lfpBandedCut = lfpBanded(isLFPFrequency, :);

    normalizedLFP = normalize(lfpCut, 1, 'norm');
    normalizedLFPNoArtifact = normalizedLFP(:, ~artifact); % Exclude artifacts

    normalizedLFPBanded = normalize(lfpBandedCut, 1, 'norm');
    normalizedLFPBandedNoArtifact = normalizedLFPBanded(:, ~artifact); % Exclude artifacts

    %% Get only parts of LFP during inactive periods
    activePeriodsNoArtifact = activePeriods(~artifact); % Exclude artifacts
    inactiveLFP = normalizedLFPNoArtifact(:, ~activePeriodsNoArtifact); % Exclude artifacts and active periods
    inactiveLFPBanded = normalizedLFPBandedNoArtifact(:, ~activePeriodsNoArtifact);

    %% Find periods of delta in this set
    [~, LFP_PCA] = pca(inactiveLFPBanded', 'NumComponents', 3);

    % Fit initial 6 component Gaussian Mixture Model (GMM)
    f = figure;
    gcfFullScreen();

    numClusters = 6;
    clusters = generateClusters(LFP_PCA, numClusters);

    charPress = 0;
    while true
        switch charPress
            case double('=')
                numClusters = numClusters + 1;
                clusters = generateClusters(LFP_PCA, numClusters);
            case double('-')
                numClusters = numClusters - 1;
                clusters = generateClusters(LFP_PCA, numClusters);
            case double('j')
                [x, ~] = ginput(2);
                clustersToJoin = clusters(round(x * 60));
                clusters(clusters == max(clustersToJoin)) = min(clustersToJoin);
            case double('s')
                [x, ~] = ginput(1);
                clusterToSplit = clusters(round(x * 60));
                clusters = splitCluster(LFP_PCA, clusters, clusterToSplit);
            case 13 % Enter key
                break;
        end

        %% Plot LFP and clusters
        sortedClusters = plotLFP(inactiveLFPBanded, lfpFrequencies, clusters);
        title(sprintf('Done! (%d clusters)', numClusters));
        waitforbuttonpress;
        charPress = double(get(gcf, 'CurrentCharacter'));
    end

    %% User selection of cluster corresponding to delta
    sleepStates = clusters;
    [x, ~] = ginput(3);
    clustersOfInterest = sortedClusters(round(x * 60));
    indicesOfInterest = ismember(sleepStates, clustersOfInterest);
    samplesOfInterest = clusters(indicesOfInterest);
    sleepStates(~indicesOfInterest) = nan;
    [~, sleepStates(indicesOfInterest)] = ismember(samplesOfInterest, clustersOfInterest);

    close(f);

    %% Cut out smaller epochs
    % Integrate results into the larger array including movement and artifacts
    behavStates = zeros(size(normalizedLFP, 2), 1);
    behavStates(~activePeriods & ~artifact') = sleepStates;
    behavStates(activePeriods) = 0;
    behavStates(artifact) = nan;

    behavStates = fillmissing(behavStates, "previous");
    finalBehavStates = modefilt(behavStates, [9 1], 'replicate');

    %% Nested Functions

    function clusters = generateClusters(data, numClusters)
        title('Calculating clusters...');
        drawnow;

        options.MaxIter = 1500;
        gmModel = fitgmdist(data, numClusters, 'Options', options);
        clusters = cluster(gmModel, data);
    end

    function clusters = splitCluster(data, clusters, clusterToSplit)
        idxOfInterest = find(clusters == clusterToSplit);
        dataOfInterest = data(idxOfInterest, :);

        clustersSplit = generateClusters(dataOfInterest, 2);
        indicesToSplitOff = idxOfInterest(clustersSplit == 2);
        indicesToMoveOver = clusters > clusterToSplit;

        clusters(indicesToMoveOver) = clusters(indicesToMoveOver) + 1; % Making space
        clusters(indicesToSplitOff) = clusterToSplit + 1;
    end

    function sortedClusters = plotLFP(lfp, frequencies, clusters)
        % Get all the samples from each cluster
        [sortedClusters, sortedClusterOrder] = sort(clusters);

        % Plot LFP
        subplot(3, 1, 1);
        imagesc((1 : size(lfp, 2)) / 60, frequencies, ...
            log10(lfp(:, sortedClusterOrder) + eps));
        axis xy;
        ylabel('Frequency (Hz)');
        xlabel('Time (min)');
        axis tight;
        ax1 = gca;

        colormap jet;
        clim([-1.5, -0.5]);

        subplot(3, 1, [2, 3]);
        plot((1 : size(lfp, 2)) / 60, sortedClusters);
        axis tight;
        ax2 = gca;

        linkaxes([ax1 ax2], 'x');
    end
end
