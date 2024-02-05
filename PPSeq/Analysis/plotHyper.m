function plotHyper(hyperparameters)
    for param = 1 : (size(hyperparameters,2) - 2)
        param_vals = unique(hyperparameters(:,param));
        param_vals(param_vals == 0) = [];
        for valIter = 1:length(param_vals)
            val = param_vals(valIter);
            data = hyperparameters(hyperparameters(:,param) == val,:);
            mn(param,valIter) = mean(data(:,7));
            err(param,valIter) = std(data(:,7))/sqrt(nnz(data));
        end
        figure
        errorbar(param_vals,mn(param,1:valIter),err(param,1:valIter))
        h = gca;
        if param ~= 1
            xlim([min(param_vals)/2, max(param_vals)*2])
            set(h,'xscale','log')
        else
            xlim([min(param_vals) - 1, max(param_vals) + 1])
        end
        title(sprintf('Parameter %d',param))
    end

