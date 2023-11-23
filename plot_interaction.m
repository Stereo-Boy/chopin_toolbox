function plot_interaction(dv, grouping_factor, covariate, handle, xlabell, ylabell, xticklabelss, mdl, plotModel)   
% dv, dependent variable data
% grouping_factor data
% covariate data (continuous)
% handle: handle of an existing figure plot or subplot
% xlabell, label for x axis
% ylabell, label for y axis
% xticklabelss, label for grouping variable on x axis
% mdl, the mdl structure
% plotModel, 0 or 1, if 1, will use data predictions in mdl structure and plot the model data
% ex of usage: 
% h=subplot(1,3,3); plot_interaction(data_8_12_27_49.one_minus_initial_orient, data_8_12_27_49.meditation, data_8_12_27_49.music, h, 'Music practice (hours)', '1 - initial orientation threshold', {'Meditators','Non-meditators'},mdls{1}, 1)  

    x = covariate(grouping_factor==1); y =  dv(grouping_factor==1);
    p1=plot(handle,x,y,'b.'); hold on; y2 =  mdl.Fitted.Response(grouping_factor==1); 
    if plotModel; plot(x,y2,'bo'); end
    ab=robustfit(x,y2); plot(handle,sort(x),ab(2).*sort(x)+ab(1),'b-');
    x = covariate(grouping_factor==2); y =  dv(grouping_factor==2);
    p2=plot(handle,x,y,'r.'); hold on; y2 =  mdl.Fitted.Response(grouping_factor==2); 
    if plotModel; plot(x,y2,'ro'); end
    ab=robustfit(x,y2); plot(handle,sort(x),ab(2).*sort(x)+ab(1),'r-')
    xlabel(xlabell); ylabel(ylabell);  legend([p1,p2],xticklabelss);
end