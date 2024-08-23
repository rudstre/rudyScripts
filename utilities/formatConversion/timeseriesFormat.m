function timeseries_new = timeseriesFormat(timeseries)
dim_t = getTimeDim(timeseries);

sz_data = size(timeseries);
dim_order = 1:length(sz_data); 
dim_order(dim_order == dim_t) = []; dim_order = [dim_t dim_order];

timeseries_new = permute(timeseries,dim_order);