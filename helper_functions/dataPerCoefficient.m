function data_per_coeff = dataPerCoefficient(data, GLME, DVName, factorList,  addNinteractions, repeatedFactorName)
% Calculate the nb of data per coefficient in a GLM or GLME, taking into account the correlated structure in the later case. 
% repeatedFactorName is the column identifying the participant/subject names that are repeated. 
% factorList is the list of factors to estimate (not the repeated factor)
% For a GLM (GLME=0), you need 10-20 datapoints for estimating each coefficient [1].
% Each continuous factor is a coefficient, each group level minus 1 is a coefficient, but also are the intercept, each interaction (nb in addNinteractions) and a free variance parameter. 
% For a GLME (GLME=1), also add a coefficient for the population variance (for intercept), but let's take into account the correlation between repeated measures. 
% Required sample size is calculated as follows: (1 + (ntrials-1) * intra-class correlation) * (nb_coefficients * minimal_nb_datapoints_per_coefficient) / ntrials. 
% Important warning: at the moment, this code works ONLY for ZERO or ONE repeated factor and for a GLME attempting to estimate intercepts, not slopes or both (so intercept is never included in GLME)
% Important warning 2: we also assumet that participants follow the same protocol with the same nb of trials - we even remove incomplete data
% [1] Frank, EH. (2015) Regression Modeling Strategies with Applications to Linear Models, Logistic and Ordinal Regression, and Survival Analysis. pp72. Second edi. Spinger.
try
if ~exist('repeatedFactorName','var')||isempty(repeatedFactorName); repeatedFactorName = {}; end
if ~exist('addNinteractions','var')||isempty(addNinteractions); addNinteractions = 0; end

data = data(:,[cellstr(repeatedFactorName), cellstr(DVName), factorList]); % restrict dataset to the columns of interest
data2 = rmmissing(data, 'DataVariables', DVName); % remove lines with missing data in DV column
k = numel(factorList); % for each factor to test, remove lines with incomplete data
n = 0; % total number of factor coefficients to estimate (a continuous factor is 1, a categorical is modalityNb - 1), add more depending on GLM/GLME
for i=1:k
    if iscell(factorList); factor = factorList{i}; else; factor = factorList; end
    if iscategorical(data.(factor)) % categorical factor
        % remove data lines with incomplete categorical factor
        tmp = data2.(factor); 
        listModality = unique(tmp(~ismissing(tmp))); % list categorical factor modalities
        U = unstack(data2,DVName,factor);
        U2 = rmmissing(U, 'DataVariables', cellstr(listModality)');
        data2 = stack(U2,cellstr(listModality)','NewDataVariableName', DVName, 'IndexVariableName', factor);
        n = n + numel(listModality) - 1;
    else % continuous factor
        n = n + 1;
    end
end
if GLME==0
    n = n + 1 + 1 + addNinteractions; % total nb of coefficients to estimate, add free variance parameter + intercept
    data_per_coeff = height(data2)/n;
    icc = 'N/A';
else
    n = n + 1 + addNinteractions; % total nb of coefficients to estimate, add population variance, not the intercept
    % Calculate the intra-class coefficient
    glme = fitlme(data2, [DVName,' ~ 1 + (1|',repeatedFactorName,')']); % Fit a model
    
    % Extract the variances / covarianceParameters returns the estimated standard deviations
    [~, ~, stats] = covarianceParameters(glme);
    sigma_b = stats{1}.Estimate(1); % Random effect standard deviation
    sigma_w = stats{2}.Estimate(1); % Residual standard deviation
    
    % Calculate ICC using variances
    icc = sigma_b^2 / (sigma_b^2 + sigma_w^2);

    % correct for the correlated structure - we will assume equal nb of trials per participant
    s = numel(unique(data2.(repeatedFactorName)));% nb of subjects
    ntrials = height(data2)/s; % per participant
    data_per_coeff = round(s.*(ntrials./(1 + (ntrials-1).*icc))./n,1);
end

dispi('ICC: ',icc,' / Nb of data points per coefficient to estimate: ', data_per_coeff);
if data_per_coeff>20||data_per_coeff<10
    warning('Be sure that the number of data per estimated coefficients is between 10 and 20: the nb of tested factors might need to be adjusted.');
end

%% debugging
catch err
   disp('Something went wrong: now in debugging mode if you need to troubleshoot (write rethrow(err) to see what''s the error).')
   keyboard 
end