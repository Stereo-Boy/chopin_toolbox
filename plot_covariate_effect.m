function plot_covariate_effect(dv, covariate, handle, xlabell, ylabell, loggX, loggY, mdl, plotModel)   
% dv, dependent variable data
% covariate data (continuous)
% handle: handle of an existing figure plot or subplot
% xlabell, label for x axis
% ylabell, label for y axis
% loggX, if 1, x is in log scale, 0 by default, optional
% loggY, if 1, y is in log scale, 0 by default, optional
% mdl, the mdl structure, optional
% plotModel, 0 or 1, if 1, will use data predictions in mdl structure and plot the model data, optional
% ex of usage: 
% h=subplot(1,3,1); plot_covariate_effect(data_8_12_27_49.one_minus_initial_orient, data_8_12_27_49.music, h, 'Music practice (hours)', '1 - initial orientation threshold', 0, 0, mdls{1},1)
if ~exist('loggX','var'); loggX=0; end
if ~exist('loggY','var'); loggY=0; end
if ~exist('plotModel','var'); plotModel=0; end

    x = covariate; y =  dv;
    plot(handle,x,y,'k.'); hold on; 
    if exist('mdl','var'); y2 =  mdl.Fitted.Response; else; y2 = zeros(size(x)); end
    if plotModel 
        plot(x,y2,'ro'); 
        ab=robustfit(x,y2); 
        plot(handle,sort(x),ab(2).*sort(x)+ab(1),'r-');
        line([x,x]',[y,y2]','Color','r');
    end
    xlabel(xlabell); ylabel(ylabell);
    if loggX==1; set(gca, 'XScale', 'log'); end
    if loggY==1; set(gca, 'YScale', 'log'); end
end