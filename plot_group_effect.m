function plot_group_effect(dv, grouping_factor, handle, xlabell, ylabell, xticklabelss,logg) 
% dv, dependent variable data
% handle: handle of an existing figure plot or subplot
% xlabell, label for x axis
% ylabell, label for y axis
% xticklabelss, label for grouping variable on x axis
% logg, if 1, y is in log scale, 0 by default
% ex of usage: 
% h=subplot(1,4,4); plot_group_effect(data.one_minus_final_orient, data.meditation, h, 'Meditation group', '1 - final orientation threshold', {'Meditators','Non-meditators'},1)
if ~exist('logg','var'); logg=0; end

    factor_levels = unique(grouping_factor);
    nbLevels = numel(factor_levels);
    colors = {'b','r','g','m','c','y'};
    medians=nan(1,nbLevels);
    for i=1:nbLevels
        lev = factor_levels(i);
        plot(handle,i.*ones(numel(dv(grouping_factor==lev))),dv(grouping_factor==lev),'Color',colors{i},'Marker','.','LineStyle','none'); hold on; 
        medians(i) = nanmedian(dv(grouping_factor==lev));
    end
    plot(handle,1:nbLevels,medians,'-k');
    xticks(1:nbLevels);xticklabels(xticklabelss); 
    xlabel(xlabell); ylabel(ylabell); 
    xlim([0.5,nbLevels+0.5]);
    if logg==1; set(gca, 'YScale', 'log'); end
end