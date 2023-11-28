function plot_covariate_effect(dv, covariate, handle, xlabell, ylabell, loggX, loggY, mdl, plotModel,model)  
% dv, dependent variable data
% covariate data (continuous)
% handle: handle of an existing figure plot or subplot
% xlabell, label for x axis
% ylabell, label for y axis
% loggX, if 1, x is in log scale, 0 by default, optional
% loggY, if 1, y is in log scale, 0 by default, optional
% mdl, the mdl structure, optional
% plotModel, 0 or 1, if 1, will use data predictions in mdl structure and plot the model data, optional
% model is used to remove flagged outliers from the data
% ex of usage: 
% h=subplot(1,4,1); 
% plot_covariate_effect(data.initial_orient, data.music, h,...
%   'Music practice (hours)', 'initial orientation threshold', 0, 0, mdls{1},1, model)
if ~exist('model','var'); model.exclude = []; plotModel=0; end
if ~exist('loggX','var'); loggX=0; end
if ~exist('loggY','var'); loggY=0; end
if ~exist('plotModel','var'); plotModel=0; end

    x = covariate; y =  dv;
    % exclude outliers
    if ~isempty(model.exclude)
       x(model.exclude) = []; 
       y(model.exclude) = []; 
    end
    plot(handle,x,y,'k.'); hold on; 
    y2 = zeros(size(x));
    if exist('mdl','var') && plotModel==1
        if model.glme == 0 %glm
            y2 =  mdl.Fitted.Response;
        else % glme
            y2 =  mdl.fitted;
        end
    else
        y2 = zeros(size(x)); 
    end
    if plotModel 
        plot(x.*1.05,y2,'ro'); 
        ab=robustfit(x.*1.05,y2); 
        plot(handle,sort(x.*1.05),ab(2).*sort(x.*1.05)+ab(1),'r-');
        line([x.*1.05,x.*1.05]',[y,y2]','Color','r');
    end
    xlabel(xlabell); ylabel(ylabell);
    xlim([min(x).*0.95,max(x).*1.1]);
    if loggX==1; set(gca, 'XScale', 'log'); end
    if loggY==1; set(gca, 'YScale', 'log'); end
end