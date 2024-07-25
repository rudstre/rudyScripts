function plotHyper(hyperparameters)
    % Plot performance metrics for different hyperparameters
    %
    % Inputs:
    %   hyperparameters: Matrix containing hyperparameter values and corresponding performance metrics

    % Iterate over each hyperparameter (excluding the last two columns, assumed to be results)
    for paramIdx = 1 : (size(hyperparameters, 2) - 2)
        % Extract unique values of the current hyperparameter
        uniqueValues = unique(hyperparameters(:, paramIdx));
        uniqueValues(uniqueValues == 0) = []; % Remove zero values if present

        % Initialize arrays for storing means and errors
        meanMetrics = zeros(1, length(uniqueValues));
        standardErrors = zeros(1, length(uniqueValues));

        % Calculate mean and standard error for each hyperparameter value
        for valueIdx = 1:length(uniqueValues)
            value = uniqueValues(valueIdx);
            relevantData = hyperparameters(hyperparameters(:, paramIdx) == value, :);
            meanMetrics(valueIdx) = mean(relevantData(:, end)); % Assuming the last column is the metric
            standardErrors(valueIdx) = std(relevantData(:, end)) / sqrt(nnz(relevantData(:, end))); % Standard error
        end

        % Plot the results with error bars
        figure;
        errorbar(uniqueValues, meanMetrics, standardErrors, 'o-');
        currentAxis = gca;

        % Set x-axis scale and limits
        if paramIdx ~= 1
            xlim([min(uniqueValues) / 2, max(uniqueValues) * 2]);
            set(currentAxis, 'xscale', 'log');
        else
            xlim([min(uniqueValues) - 1, max(uniqueValues) + 1]);
        end

        % Set plot title and labels
        title(sprintf('Hyperparameter %d', paramIdx));
        xlabel(sprintf('Hyperparameter %d Values', paramIdx));
        ylabel('Performance Metric');
    end
end
