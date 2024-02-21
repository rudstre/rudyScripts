importTrialData;


pn = uigetdir('~/*.txt','Select output folder');
hyperparameters = readmatrix(fullfile(pn,'results/hyperparameters.txt'));

hyperlist = readmatrix(fullfile(pn,'hyperlist.txt'));
[~,idx_unq] = unique(hyperparameters(:,1:5),'rows');
dupRows = setdiff(1:size(hyperparameters,1), idx_unq);
hyperparameters(dupRows,:) = [];

[~,idx] = ismember(hyperparameters(:,1:5),hyperlist,'rows');

hyperparams = zeros([length(hyperlist) 7]);
hyperparams(:,1:5) = hyperlist;
hyperparams(idx,6:7) = hyperparameters(:,6:7);

[~,ord] = sort(hyperparams(:,7),'descend');

hyperparams_sorted = hyperparams(ord,:);

