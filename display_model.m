function display_model(mdl, model)
% mdl the model object to plot (obtained through all_glm / fitglm / fitglme functions
% glme: whether this is a glme or not (default 0)
if ~exist('model','var') || isfield(model,'glme')==0; model.glme = 0; end
if ~exist('model','var') || isfield(model,'p_adjust_method')==0; model.p_adjust_method = 'none'; end % default 'none', other options are 'benjamini-hochberg', 'bonferroni'
if ~exist('model','var') || isfield(model,'nb_tests')==0; model.nb_tests = numel(mdl.CoefficientNames)-1; end % minus 1 because it assumes intercept is included
try
    disp('Summary of variable formats in the model')
    disp(mdl.VariableInfo(mdl.VariableInfo.InModel==1,:))
    
    disp('Summary of the model')
    disp(mdl)
    if model.glme==1 % this is a GLME
        dispi('AIC: ',mdl.ModelCriterion.AIC)
        numplots = 3;
    else % this is a GLM
        dispi('AICc: ',mdl.ModelCriterion.AICc)
    end
    dispi('Adjusted R^2: ',round(100*mdl.Rsquared.Adjusted,1),'%')
    dispi('R^2: ',round(100*mdl.Rsquared.Ordinary,1),'%')
    [H, P, KSstat] = kstest((mdl.Residuals.raw-nanmean(mdl.Residuals.raw))./nanstd(mdl.Residuals.raw));
    dispi('Residuals: Kolmogorov test for normality (alpha 5%):  KS = ',sprintf('%.2f',KSstat),', p = ',sprintf('%.4f',P));
    if H==1; disp('Residuals are not normal'); else; disp('Residuals are normal'); end
    
    % plot diagnostics
    figure('Color', 'w', 'units','normalized','outerposition',[0 0.1 1 0.5]);
    if model.glme==0 % this is a GLM
        numplots = 4;
        subplot(1,numplots,3); plotDiagnostics(mdl,'cookd')
    end
    subplot(1,numplots,1); plotResiduals(mdl,'fitted','ResidualType','Pearson');
    subplot(1,numplots,2); plotResiduals(mdl);   
    
    % write formated results with p adjusted for multiple comparison (or not)
    % first extract useful data
    if model.glme==0 % this is a GLM
        anovas = table(mdl.CoefficientNames', mdl.Coefficients.tStat, ones(numel(mdl.CoefficientNames),1).*mdl.DFE, mdl.Coefficients.pValue,'VariableNames',{'Name','tStat','DF','pValue'});
    else
        anovas = table(mdl.Coefficients.Name, mdl.Coefficients.tStat, mdl.Coefficients.DF, mdl.Coefficients.pValue,'VariableNames',{'Name','tStat','DF','pValue'});
    end
    
    % remove intercept 
    anovas(1,:)=[];
    
    % reorder the factors by increasing p values
    [~,idx]=sort(anovas.pValue);
    anovas = anovas(idx,:);
    
    % define thresholds
    alpha = 0.05; 
    H_reject = zeros(size(anovas,1),1); % hypotheses rejection (1)
    adj_alpha = ones(size(anovas,1),1).*alpha; % values of adjusted alphas
    
    % adjust p values and decide hypothesis rejection
    switch model.p_adjust_method
        case{'none'}
            disp('No adjustment for multiple comparisons')
            anovas.adj_pValue = anovas.pValue;
            anovas.H_reject = anovas.adj_pValue<=alpha;
        case{'benjamini-hochberg'}
            disp('Adjustment for multiple comparisons: method of Benjamini-Hochberg')
            first_no_reject = 0; % as soon as one hypothesis is not rejected, the larger p-values are also rejected
            for i=1:size(anovas,1)
                % apply p adjustment
                adj_alpha(i) = i.*alpha./model.nb_tests;
                if anovas.pValue(i)<=adj_alpha(i) && first_no_reject == 0
                    H_reject(i) = 1;
                else
                    first_no_reject = 1;
                end
            end
            anovas.adj_alpha = adj_alpha;
            anovas.adj_pValue = min(1,anovas.pValue.*alpha./adj_alpha);
            anovas.H_reject = H_reject;
        case{'bonferroni'}
            disp('Adjustment for multiple comparisons: method of Bonferroni')
            adj_alpha = alpha/model.nb_tests;
            anovas.adj_pValue = min(1,anovas.pValue.*alpha./adj_alpha);
            anovas.H_reject = anovas.adj_pValue<=alpha;
    end
    % show the results
    disp(anovas)
    for j=1:size(anovas,1)
        if anovas.H_reject(j) == 1 %reject
           result = 'Significant';
        else
           result = 'No significant';
        end
        dispi(result,' effect of ',anovas.Name{j},' (t(',anovas.DF(j),') = ',round(anovas.tStat(j),2),', adjusted p = ',anovas.adj_pValue(j),')')
    end
    
%% debugging
catch err
   keyboard 
end