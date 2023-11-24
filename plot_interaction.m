function plot_interaction(dv, grouping_factor, covariate, handle, xlabell, ylabell, legendLabels, mdl, plotModel, model) 
% Plot interaction effect for a dependent variable between a covariate (in x axis) and a grouping factor (put in legend)
% The covariate can also be categorical but the grouping factor has to have two levels only.
% dv, dependent variable data
% grouping_factor data (2 levels only)
% covariate data (continuous or categorical)
% handle: handle of an existing figure plot or subplot
% xlabell, label for x axis
% ylabell, label for y axis
% legendLabels, label for grouping variable in legend
% mdl, the mdl structure
% plotModel, 0 or 1, if 1, will use data predictions in mdl structure and plot the model data
% ex of usage: 
% h=subplot(1,4,4); 
% plot_interaction(data.Time, data.stereo,data.ageGroup, h,...
%     'Age group (younger / older)','Task completion time (sec)', {'Monocular','Binocular'},mdls{1}, 1, model)  
if ~exist('model','var'); model.exclude = []; end
if ~exist('plotModel','var'); plotModel=0; end

    % exclude outliers
    if ~isempty(model.exclude) 
       dv(model.exclude) = []; 
       grouping_factor(model.exclude) = []; 
       covariate(model.exclude) = []; 
    end
    
    levels = unique(grouping_factor);
    
    % plot for grouping_factor = first value
    x = covariate(grouping_factor==levels(1)); y =  dv(grouping_factor==levels(1));
    p1=plot(handle,x,y,'b.'); hold on; y2 =  mdl.Fitted.Response(grouping_factor==levels(1)); 
    if plotModel;  m1 = plot(1.05*x,y2,'bo'); end
    ab=robustfit(x,y2);plot(handle,sort(x),ab(2).*sort(x)+ab(1),'b-');
    
    % plot for grouping_factor = second value
    x = covariate(grouping_factor==levels(2)); y =  dv(grouping_factor==levels(2));
    p2=plot(handle,x,y,'r.'); hold on; y2 =  mdl.Fitted.Response(grouping_factor==levels(2)); 
    if plotModel; m2 = plot(1.05*x,y2,'ro'); end
    ab=robustfit(x,y2); plot(handle,sort(x),ab(2).*sort(x)+ab(1),'r-')
    xlabel(xlabell); ylabel(ylabell);  
    
    % plot legend
    if plotModel
        legend([p1,p2,m1,m2],{legendLabels{1},legendLabels{2},'Model estimates','Model estimates'});
    else
        legend([p1,p2],legendLabels);
    end
    
    % plot x limits
    xlim([0.5,2.5])
end