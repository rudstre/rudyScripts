function fullScreen(f)

if nargin == 0
    f = gcf;
end

set(f,'units','normalized','outerposition',[0 0 1 1])
