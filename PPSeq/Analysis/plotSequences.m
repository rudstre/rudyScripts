function plotSequences(data,session,t_start,sequences)

ts = sequences.ts;
type = sequences.type;
offsets = sequences.offsets;
widths = sequences.widths;
amps = sequences.amplitudes;

leverTimes = data(session).leverOnTimes;
leverTimes_z = leverTimes - t_start;
leverTimes_z = leverTimes_z/1000;
valid = iswithin(leverTimes_z,-1,max(ts)+1);
leverTimes_z = leverTimes_z(valid);

leverOff = data(session).leverOffTimes;
leverOff_z = leverOff - t_start;
leverOff_z = leverOff_z/1000;
leverOff_z = leverOff_z(iswithin(leverOff_z,-1,max(ts)+1));

leverCh = data(session).leverCh(valid);

for j = 1:max(type)
    vals = zeros([1,5000]);
    for i = 1:40
        mu = offsets(i,j);
        sigma = widths(i,j);
        x = linspace(-5,5, 5000);
        vals = vals+exp(amps(i,j))*normpdf(x,mu,sigma);
    end
    
     val_smooth = movmean(vals,15);
     wvfm{j} = val_smooth/max(val_smooth)*.1+1;
end

leverOn1 = leverTimes_z(leverCh==1);
leverOn2 = leverTimes_z(leverCh==2);
leverOff1 = leverOff_z(leverCh==1);
leverOff2 = leverOff_z(leverCh==2);

xline(leverOn2(1),'--r')
hold on
xline(leverOff2(1),'-r')
xline(leverOn1(1),'--b')
xline(leverOff1(1),'-b')

xline(leverOn1(2:end),'--b','HandleVisibility','off')
xline(leverOn2(2:end),'--r','HandleVisibility','off')
xline(leverOff1(2:end),'-b','HandleVisibility','off')
xline(leverOff2(2:end),'-r','HandleVisibility','off')

col_array = {'magenta', 'green','cyan','black','blue','red'};
for i = 1:max(type)
    for j = 1:length(ts(type == i))
        all_ts = ts(type == i);
        ts_center = all_ts(j);
        if j == 1
            str = 'on';
        else
            str = 'off';
        end
        line('XData',x + ts_center,'YData',wvfm{i},'Color',col_array{i},'HandleVisibility',str)
    end
end

xlim([0, 20])
ylim([.9, 1.2])
legend_cell = {'lever 1 on','lever 1 off','lever 2 off','lever 2 off'};
for i = 1:max(type)
    legend_cell{end+1} = sprintf('sequence %d',i);
end
legend(legend_cell)