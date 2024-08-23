function dim = getTimeDim(timeseries)

sz_time = size(timeseries);
[~,dim] = max(size(sz_time));

ratios = sz_time/dim; ratios(dim) = [];

if any(ratios < 3)
    error('Can''t tell!')
end