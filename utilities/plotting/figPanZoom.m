function f = figPanZoom

% A figure
f = figure('menubar','none');

% Add menus with Accelerators
mymenu = uimenu('Parent',f,'Label','Hot Keys');
uimenu('Parent',mymenu,'Label','Zoom','Accelerator','z','Callback',@(src,evt)zoom(f,'xon'));
uimenu('Parent',mymenu,'Label','Rotate','Accelerator','r','Callback',@(src,evt)rotate3d(f,'on'));
uimenu('Parent',mymenu,'Label','Pan','Accelerator','p','Callback',@(src,evt)pan(f,'xon'));
end