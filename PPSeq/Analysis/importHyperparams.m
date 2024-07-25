% Import trial data
importTrialData;

% Prompt user to select the output folder containing .txt files
outputFolder = uigetdir('~/*.txt', 'Select output folder');

% Read hyperparameters and hyperlist from the specified files
hyperparameters = readmatrix(fullfile(outputFolder, 'results/hyperparameters.txt'));
hyperlist = readmatrix(fullfile(outputFolder, 'hyperlist.txt'));

% Identify unique hyperparameters and remove duplicates
[~, uniqueIdx] = unique(hyperparameters(:, 1:5), 'rows');
duplicateRows = setdiff(1:size(hyperparameters, 1), uniqueIdx);
hyperparameters(duplicateRows, :) = [];

% Match unique hyperparameters with the hyperlist
[~, idx] = ismember(hyperparameters(:, 1:5), hyperlist, 'rows');

% Initialize the final matrix for storing hyperparameters and results
hyperparams = zeros(length(hyperlist), 7);
hyperparams(:, 1:5) = hyperlist;
hyperparams(idx, 6:7) = hyperparameters(:, 6:7);

% Sort hyperparameters based on the 7th column in descending order
[~, ord] = sort(hyperparams(:, 7), 'descend');
hyperparams_sorted = hyperparams(ord, :);
