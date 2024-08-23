function strout = escapeString(strin)
    specialChars = {'\', '_', '^', '{', '}', '~', '#', '%', '&', '$'};
    latexEquivalents = {'\\', '\_', '\^{}', '\{', '\}', '\~{}', '\#', '\%', '\&', '\$'};
    
    strout = strin;
    for k = 1:length(specialChars)
        strout = strrep(strout, specialChars{k}, latexEquivalents{k});
    end
end