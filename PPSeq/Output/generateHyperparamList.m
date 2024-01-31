function hyperMat = generateHyperparamList(hyperCell)
    lngths = cellfun(@length,hyperCell);
    [a,b,c,d,e] = ndgrid(1:lngths(1),1:lngths(2),1:lngths(3),1:lngths(4),1:lngths(5));
    paramOrder = sortrows([a(:),b(:),c(:),d(:),e(:)],1);

    for i = 1:length(hyperCell)
        cur_param = hyperCell{i};
        hyperMat(:,i) = cur_param(paramOrder(:,i));
    end
    writematrix(hyperMat,'hyperlist.txt','Delimiter','space')
end