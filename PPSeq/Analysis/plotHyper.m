for param = 1 : (size(hyperparameters,2) - 1)
    param_vals = unique(hyperparameters(:,param));
    for valIter = 1:length(param_vals)
        val = param_vals(valIter);
        data = hyperparameters(hyperparameters(:,param) == val,:);
        mn(param,valIter) = mean(data(:,6));
        err(param,valIter) = std(data(:,6))/sqrt(nnz(data));
    end
    figure
    errorbar(param_vals,mn(param,:),err(param,:))
    h = gca;
    if param ~= 1
        xlim([min(param_vals)/2, max(param_vals)*2])
        set(h,'xscale','log')
    else
        xlim([min(param_vals) - 1, max(param_vals) + 1])
    end
    title(sprintf('Parameter %d',param))
end

