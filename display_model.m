function display_model(mdl, glme)
% mdl the model object to plot (obtained through all_glm / fitglm / fitglme functions
% glme: whether this is a glme or not (default 0)
if ~exist('glme','var'); glme = 0; end
    disp(mdl)
    if glme==1 % this is a GLME
        dispi('AIC: ',mdl.ModelCriterion.AIC)
    else % this is a GLM
        dispi('AICc: ',mdl.ModelCriterion.AICc)
    end
    dispi('Adjusted R^2: ',round(100*mdl.Rsquared.Adjusted,1),'%')
    [H, P, KSstat] = kstest((mdl.Residuals.raw-nanmean(mdl.Residuals.raw))./nanstd(mdl.Residuals.raw));
    dispi('Residuals: Kolmogorov test for normality (alpha 5%):  KS = ',sprintf('%.2f',KSstat),', p = ',sprintf('%.4f',P));
    if H==1; disp('Residuals are not normal'); else; disp('Residuals are normal'); end
    
    figure('Color', 'w', 'units','normalized','outerposition',[0 0.1 1 0.5]);
    if glme==1 % this is a GLME
        numplots = 3;
    else   % this is a GLM
        numplots = 4;
        subplot(1,numplots,3); plotDiagnostics(mdl,'cookd')
    end
    subplot(1,numplots,1); plotResiduals(mdl,'fitted','ResidualType','Pearson');
    subplot(1,numplots,2); plotResiduals(mdl);    
end