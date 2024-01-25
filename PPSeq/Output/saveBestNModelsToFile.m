function saveBestNModelsToFile(hyperparameters,n)
    hyper_sorted = sortrows(hyperparameters,6,'descend');
    writematrix(hyper_sorted(1:n,:),'top_params.txt');
end
