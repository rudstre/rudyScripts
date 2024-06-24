function [res,gidx] = calcImpMatrix(imp,highThr)

if nargin < 2
    highThr = 2e6;
end

for i = 1:size(imp,2)
    res(i,1) = sum(iswithin(imp,0,1e5));

    gidx = logical(iswithin(imp,1e5,highThr));
    res(i,2) = sum(gidx);
    
    res(i,3) = sum(iswithin(imp,highThr,inf));
end





