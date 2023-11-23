function display_model(mdl)
    disp(mdl)
    dispi('AICc: ',mdl.ModelCriterion.AICc)
    dispi('Adjusted R^2: ',round(100*mdl.Rsquared.Adjusted,1),'%')
    [H, P, KSstat] = kstest((mdl.Residuals.raw-nanmean(mdl.Residuals.raw))./nanstd(mdl.Residuals.raw));
    dispi('Residuals: Kolmogorov test for normality (alpha 5%):  KS = ',sprintf('%.2f',KSstat),', p = ',sprintf('%.4f',P));
    if H==1; disp('Residuals are not normal'); else; disp('Residuals are normal'); end
    
    figure('Color', 'w', 'units','normalized','outerposition',[0 0.1 1 0.5]);
    subplot(1,4,1); plotDiagnostics(mdl,'cookd')
    subplot(1,4,2); plotResiduals(mdl,'fitted','ResidualType','Pearson');
    subplot(1,4,3); plotResiduals(mdl);    
end