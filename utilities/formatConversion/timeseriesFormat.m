function reorderedData = timeseriesFormat(data)
% Reorder dimensions so the time dimension comes first

timeDim = getTimeDim(data);  % Identify the time dimension
dimOrder = 1:ndims(data);
dimOrder(dimOrder == timeDim) = [];
dimOrder = [timeDim, dimOrder];  % Move time dimension to the first position

reorderedData = permute(data, dimOrder);
end
