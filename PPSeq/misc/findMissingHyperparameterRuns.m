function missing = findMissingHyperparameterRuns(resultsPath,hyperlist)
    
    files = dir(resultsPath);

    reg = '[^0-9]*([0-9]+).*';
    for i = 3:length(t)
        tk = regexp(files(i).name,reg,'tokens');
        tokens(i) = str2num(tk{1}{1});
    end

    missing = find(~ismember(1:size(hyperlist,1),tokens));