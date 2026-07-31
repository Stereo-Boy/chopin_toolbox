function plot_group_effect(dv, grouping_factor, handle, xlabell, ylabell, xticklabelss, logg, model, jitterPt)
% plot the dv as a function of the group on a dv
% dv, dependent variable data
% handle: handle of an existing figure plot or subplot
% xlabell, label for x axis
% ylabell, label for y axis
% optional - xticklabelss, labels for grouping variable on x axis (if empty or not provided, read them from grouping_factor levels directly)
% logg, if 1, y is in log scale, 0 by default
% model is used to remove flagged outliers from the data
% jitterPt is how much jitter to add in pts (max)
% ex of usage: 
% h=subplot(1,4,4); 
% plot_group_effect(data.final_orient, data.meditation, h, 'Meditation group', 'final orientation threshold', '',0, model)
if ~exist('logg','var'); logg=0; end
if ~exist('model','var'); model.exclude = []; end

factor_levels = unique(grouping_factor);
factor_levels = factor_levels(~ismissing(factor_levels));
nbLevels = numel(factor_levels);

if ~exist('xticklabelss','var')||isempty(xticklabelss)
    xticklabelss = cellstr(string(factor_levels));
end
if ~exist('jitterPt','var')||isempty(jitterPt); jitterPt=0.2; end

if ~isempty(model.exclude)
    dv(model.exclude) = [];
    grouping_factor(model.exclude) = [];
end

% convert grouping factor to numeric index (1..nbLevels) based on factor_levels order
[~, xNum] = ismember(grouping_factor, factor_levels);

% add jitter
xJit = xNum + jitterPt.*(2.*rand(numel(xNum),1)-1);

colors = lines(nbLevels); % generates distinct colors for any number of groups
medians = nan(1,nbLevels);

axes(handle); hold(handle,'on');
for i=1:nbLevels
    idx = (xNum==i);
    plot(handle, xJit(idx), dv(idx), 'Color', colors(i,:), 'Marker','.', 'LineStyle','none');
    medians(i) = nanmedian(dv(idx));
end
plot(handle, 1:nbLevels, medians, '-k');

xticks(handle,1:nbLevels); xticklabels(handle,xticklabelss);
xlabel(handle,xlabell); ylabel(handle,ylabell);
xlim(handle,[0.5, nbLevels+0.5]);

if logg==1
    set(handle, 'YScale', 'log');
else
    if ~any(dv<0)
        c = ylim(handle);
        ylim(handle,[0 c(2)]);
    end
end
end