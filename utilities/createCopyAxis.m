function ax_copy = createCopyAxis(ax)
ax_copy = copyobj(ax, gcf); delete(get(ax_copy, 'Children'));
set(ax_copy,'visible','off')
linkaxes([ax,ax_copy])