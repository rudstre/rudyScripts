function dt = tick2datetime(ticks)
if ~isnumeric(ticks)
    ticks = str2num(ticks);
end
days_oi = ticks/(1e7*60*60*24);
dt = datetime(days_oi + datenum(1,1,1),'ConvertFrom','datenum');