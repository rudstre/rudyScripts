function tset(input,sz)

if nargin < 2
    sz = 18;
end
if nargin < 1
    h = gca;
end

if isa(input,'ax')
    h = input;
elseif isa(input,'figure')
    h = gca(input);
elseif isa(input,'matlab.graphics.layout.TiledChartLayout')
    h = [input.Title,input.XLabel,input.YLabel];
end

set(h,'FontSize',sz)

end