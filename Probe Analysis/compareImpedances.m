function [gg,gb,bg,bb] = compareImpedances(imp1,imp2,thr)
if nargin < 3
    thr = 2e6;
end

data = [imp1, imp2];

gg = data(all(data < thr,2),:);
bb = data(~any(data < thr,2),:);
gb = data(imp1 < thr & imp2 >= thr,:);
bg = data(imp1 >= thr & imp2 < thr,:);


%% Plot
scatter(gg(:,1)/1e6,gg(:,2)/1e6,18,'g','filled')
hold on
scatter(gb(:,1)/1e6,gb(:,2)/1e6,18,'r','filled')
scatter(bb(:,1)/1e6,bb(:,2)/1e6,18,'black','filled')
scatter(bg(:,1)/1e6,bg(:,2)/1e6,18,'blue','filled')

yline(thr/1e6,'--r','LineWidth',1.5)
fplot(@(x) x,'--b','LineWidth',1.5)

xl = get(gca,'XLim'); yl = get(gca,'YLim');
xlim([0 xl(2)]), ylim([0 yl(2)])
xlabel('Data 1 (M\Omega)')
ylabel('Data 2 (M\Omega)')

legend({'good/good','good/bad','bad/good','bad/bad','threshold','y=x'})

tset

