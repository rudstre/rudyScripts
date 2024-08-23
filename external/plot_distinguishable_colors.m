function plot_distinguishable_colors(ncols,bkg)
cols = distinguishable_colors(ncols,bkg);
figure
for i = 1:size(cols,1)
    hold on
    rectangle("Position",[2*(i-1),0,1,1],"FaceColor",cols(i,:))
end
xlim([0,2*(i-1) + 1])