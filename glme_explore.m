function [mdl1,mdl2]=glme_explore(data, varargin)
% Applies a General Linear Mixed-Effect Model on data with varargin parameters
% Needs to have a formula as the first varargin term!
% Accept a varargin argument plotIt which does not show the diagnostic
% figure when = 0
close all
warning('off','all')

% isolate target
formula = varargin{1};
targetInd = strfind(formula, '~');
targetName = formula(1:targetInd-2);
target = table2array(data(:,targetName));

if any(strcmpi(varargin,'plotIt')); i=find(strcmpi(varargin,'plotIt')); plotIt = varargin{i+1}; varargin(i:i+1)=[]; else ; plotIt=1; end
if plotIt
    figure('Color', 'w','Units','normalized','Position',[0 0 0.9 0.9])
    subplot(2,3,1); hist(target);
    xlabel(targetName); ylabel('n'); title('Response distribution');
end
findist=0;
if any(strcmpi(varargin,'distribution')) 
    i=find(strcmpi(varargin,'distribution')); distribution = varargin{i+1}; varargin(i:i+1)=[]; 
else
    findist=1;
    distribution='normal'; 
end

disp('Is the dependent variable distribution different from a normal one?')
SH_stats = shapiro(target);        P1 = SH_stats{2,7};  w = SH_stats{2,5};
dispi('Shapiro-Wilk test for normality (alpha 5%):  W = ',sprintf('%.2f',w),', p = ',sprintf('%.4f',P1));

if findist==1 && P1<0.05 && any(target<0)==0
    %non-normal distribution - find another one
        if ~any(mod(target,1)~=0)
           if ~any(target<0) 
               distribution = 'poisson'; 
               if ~any(target>1);   distribution = 'binomial'; end
           end
        else
            if any(target==0)==0
                distribution = 'gamma';
            else
                distribution = 'normal';
            end
        end
end
if any(strcmpi(varargin,'link')); i=find(strcmpi(varargin,'link')); link = varargin{i+1}; varargin(i:i+1)=[]; else 
    switch distribution %standard link for each distribution
        case{'gamma','Gamma'}
            link = 'reciprocal';
        case{'normal','Normal','gaussian'}
            link = 'identity';
        case{'poisson', 'Poisson'}
            link = 'log';
        case{'binomial' , 'Binomial'} 
            link = 'logit';
        case{'InverseGaussian'  , 'inversegaussian'}
            link = -2;
    end
end
mdl1=runGLM(data,distribution,link,[],[],varargin); disp(mdl1);
if ~isempty(mdl1)
    dispi('AIC: ',mdl1.ModelCriterion.AIC); 
    subplot(2,3,2); plotResiduals(mdl1,'fitted','ResidualType','Pearson');
    subplot(2,3,3); plotResiduals(mdl1);
    SH_stats2 = shapiro(mdl1.residuals);        P2 = SH_stats2{2,7};  w2 = SH_stats2{2,5};
    dispi('Residuals: Shapiro-Wilk test for normality (alpha 5%):  W = ',sprintf('%.2f',w2),', p = ',sprintf('%.4f',P2));   
    dispi('Explained variance R^2: ',mdl1.Rsquared.Adjusted)
end

% find the best model
disp('Trying alternative models')
alt_distr = {};
if P1>0.05; alt_distr(end+1) = {'normal'}; end
if any(target<0)==0
    if any(target==0)==0;      alt_distr(end+1) = {'gamma'};     alt_distr(end+1) = {'InverseGaussian'}; end
    if ~any(mod(target,1)~=0) 
         alt_distr(end+1) = {'poisson'};   
         if ~any(target>1);              alt_distr(end+1) = {'binomial'}; end 
     end
end
alt_links={'identity','reciprocal','log','logit',-2,'loglog','comploglog','probit'}; 
AICs = []; residualsNorm = []; distributions={}; links = {};
for i=1:numel(alt_distr)
    for j=1:numel(alt_links)
        distributions(end+1) = alt_distr(i);
        links(end+1) = alt_links(j);
        [~,AICs,residualsNorm]=runGLM(data,alt_distr{i},alt_links{j},AICs,residualsNorm,varargin);
    end
end
models = sortrows(table(distributions',links',AICs',residualsNorm','VariableNames',{'distribution','link','AIC','Residual_normality'}),'AIC');
disp(models)
if numel(models)<=0
    disp('No other model compatible')
    mdl2=[];
else
    disp('Selecting best AIC model, running it and plotting it on second line of the figure: ')
    disp(models(1,:))
    mdl2=runGLM(data,table2array(models(1,'distribution')),table2array(models(1,'link')),[],[],varargin); disp(mdl2);
    subplot(2,3,5); plotResiduals(mdl2,'fitted','ResidualType','Pearson');
    subplot(2,3,6); plotResiduals(mdl2);
    SH_stats2 = shapiro(mdl2.residuals);        P2 = SH_stats2{2,7};  w2 = SH_stats2{2,5};
    dispi('Residuals: Shapiro-Wilk test for normality (alpha 5%):  W = ',sprintf('%.2f',w2),', p = ',sprintf('%.4f',P2));
    dispi('Explained variance R^2: ',mdl2.Rsquared.Adjusted)
end
warning('on','all')
end

function [mdl,AICs,residualsNorm]=runGLM(data,distribution,link,AICs,residualsNorm,varargin)
skip = 0;
varargin=varargin{:};
try
    if iscell(link); link=link{1}; end
    commands = 'data';
    for i=1:numel(varargin)
        tmp = varargin{i}; if iscell(tmp); tmp = tmp{1}; end
        if ~isnumeric(tmp); commands = [commands,',''',tmp,'''']; else; commands = [commands,',',num2str(tmp)]; end
    end  
    eval(['mdl = fitglme(',commands,',''distribution'',distribution,''link'',link);']);
    
catch err
   disp(err.message)
   dispi('We ignore the model with distribution ',distribution,' and link ',link)
   mdl=[]; AICs(end+1) = 100000; 
   residualsNorm(end+1) = nan;
   skip = 1;
end
if skip==0
    if isempty(mdl) || isnan(mdl.ModelCriterion.AIC) || ~isreal(mdl.ModelCriterion.AIC) || mdl.ModelCriterion.AIC>1000000000 || ~isreal(mdl.Coefficients{2,2})
        dispi('We ignore the model with distribution ',distribution,' and link ',link)
        mdl=[]; AICs(end+1) = 100000;
        residualsNorm(end+1) = nan;
    else
        AICs(end+1) = mdl.ModelCriterion.AIC;
        try
            SH_stats2 = shapiro(mdl.Residuals.Raw);        P2 = SH_stats2{2,7};  w2 = SH_stats2{2,5};
        catch
            SH_stats2 = shapiro(mdl.Residuals);        P2 = SH_stats2{2,7};  w2 = SH_stats2{2,5}; 
        end
        residualsNorm(end+1) = P2>0.05;
    end
end
end