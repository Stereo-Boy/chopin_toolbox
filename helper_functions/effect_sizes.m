function effect_sizes_table = effect_sizes(mdl, model)
% Calculate local Cohen's f2 (f squared) for mixed effect model.
% For each continuous predictor, we follow the rational in Selya et al. (2012) - A Practical Guide to Calculating Cohents f2, a Measure of Local Effect Size, from PROC MIXED.
% It will output the local effect sizes for each continous factor in the model.
%
% Inputs:
% mdl is one particular cell of the output from all_glm
% model is a model structure
%
% Example of usage:
% model.data = data;
% model.dv = 'Time';
% model.distribution = 'normal';
% model.max_nb_factors = 10;
% model.solid_factors = {''}; %keep these between {}
% model.liquid_factors = {'(1|Participant)','(1|task)','trial','load','stereo','ageGroup','ageGroup:stereo','load:stereo','ageGroup:load','load:ageGroup:stereo'}; %keep these between {}
% model.links = {'log'}; %{'log','identity'}; % identity was also tested but consistently underperformed
% mdls = all_glm(model);
% effect_sizes(mdls{1}, model)

try
effect_sizes_table = [];
% first create a list of fixed factors and dependent variable
[list_factors, dv] = split_factors(mdl.Formula);

% first check that dependent variable is continuous, and if yes, continue, otherwise just stop
if iscategorical(dv)
    disp('Dependent variable is not continuous so we cannot easily extract a local effect size.')
    return
end

% redefine model structure to match mdl, except for solid factors
model.liquid_factors = {''};
if isfield(mdl.Distribution,'Name')
    model.distribution = mdl.Distribution.Name; % GLM case
else
    model.distribution = mdl.Distribution; % GLME case
end
model.links = {mdl.Link.Name}; 
model.max_nb_factors = numel(list_factors);
model.p_adjust_method = 'none';

% now loop through the list to create a model without the factor and extract its f2
f2s = []; f2sizes = {}; iter = 1; types = {}; list_factors_es = {};
if numel(list_factors)>1
    for i=1:numel(list_factors)
        factor = list_factors{i};
        idx = find(strcmp(mdl.VariableInfo.Row,factor)); % locate factor in mdl VariableInfo
        if ~mdl.VariableInfo.IsCategorical(idx) % if continuous, calculate f2
            model.solid_factors = list_factors(~cellfun(@(x) strcmp(x,list_factors{i}), list_factors)); % select all factors but the ith one
            mdls = all_glm(model,0); % run the model with verbose off
            f2s(iter) = round((mdl.Rsquared.Ordinary - mdls{1}.Rsquared.Ordinary)/(1-mdl.Rsquared.Ordinary),2);
            types(iter) = {'Cohen''s f2'};
        else % for categorical, we use Cohen's d calculated from t-stat
            if contains(factor,'|') % in case of random effects, skip because the anova table only has fixed effects
                continue
            else
                f2s(iter) = get_cohens_d(mdl, factor);
                types(iter) = {'Cohen''s d'};
            end
        end
        f2sizes(iter) = {interpret_f2(f2s(iter),types{iter})};
        list_factors_es(iter) = {factor};
        dispi('Local effect size for ',factor,' : ',types{iter},' = ',f2s(iter),' (',f2sizes{iter},')')
        iter = iter + 1;
    end
else
    factor = list_factors{1};
    idx = find(strcmp(mdl.VariableInfo.Row,factor)); % locate factor in mdl VariableInfo
    if ~mdl.VariableInfo.IsCategorical(idx) % if continuous, calculate f2
        % when there is only one factor, we just calculate the model f2
        f2s(1) = round(mdl.Rsquared.Ordinary/(1-mdl.Rsquared.Ordinary),2);
        types(1) = {'Cohen''s f2'};
    else %for categorical, we use Cohen's d calculated from t-stat
         if contains(factor,'|') % in case of random effects, skip because the anova table only has fixed effects
                f2s(1) = nan;
                types(1) = {'None'};
         else
                f2s(1) = get_cohens_d(mdl, factor);
                types(1) = {'Cohen''s d'};
         end
    end
    f2sizes(1) = {interpret_f2(f2s(1), types{1})};
    list_factors_es(1) = {factor};
    dispi('Local effect size for ',factor,' : ',types{1},' = ',f2s(1),' (',f2sizes{1},')')
end
effect_sizes_table = table(list_factors_es',types',f2s',f2sizes','VariableNames',{'Factor','Type','ES','Interpretation'});

catch err
    disp('Error caught: for debugging, write rethrow(err)')
    keyboard
end
end

function [terms, dv] = split_factors(formula) % we could have used VariableInfo instead but this also gets us interaction terms and dv (which can be also found in mdl.ResponseName)
% Split the formula into terms and dv
    % first convert the model class in string
    formula = char(formula);

     % remove '~' and leading/trailing spaces
    terms = strsplit(formula, '~');
    dv = terms{1};
    terms = strtrim(terms{2});

    % split between + terms
    terms = strsplit(terms, '+'); 
    
    % remove the term '1'
    terms = terms(~strcmp(strtrim(terms), '1'));
    
    % remove empty spaces
    terms = cellfun(@(x) strrep(x, ' ', ''), terms, 'UniformOutput', false);
    
    % remove empty cells if any
    terms(cellfun(@isempty, terms))=[];
end

function d = get_cohens_d(mdl, factor)
    % see whether factor is in the stat list
    mdl_factor_list = mdl.Coefficients.Name;
    idx = find(strcmp(mdl_factor_list,factor));
    if numel(idx)==0 % no, we probably need to edit the names
        for j=1:numel(mdl_factor_list)
            nameJ = char(mdl_factor_list{j});
            if numel(strfind(nameJ,':'))>0 % interaction detected, split the factors by :
                nameJs = strsplit(nameJ,':');
            else
                nameJs = {nameJ};
            end
            for n = 1:numel(nameJs)  % for each factor attempt to remove anything after _ in the factor name (likely modality name)
                tmp = strsplit(nameJs{n},'_');
                if numel(tmp)>2; warning('It is likely that your factor name contrained a _ character. This is annoying for what we do here: consider removing that _ to avoid errors.'); end
                nameJs(n) = tmp(1); % we only take the first part before any _ character - we hope that there is no underscore in the name other than the one added by the program to code modality
            end
            mdl_factor_list(j) = {strjoin(nameJs,':')}; % reconcatenate factors together in case of interaction using :
        end
        idx = find(strcmp(mdl_factor_list,factor)); % and finally attempt again to localize factor in the list
    end
    if numel(idx)==0 % still 0, problem detected
        warning('We are not able to find the factor of interest in the list of factors provided - check code.')
        keyboard
        d = nan;
    else % otherwise continue
        t = mdl.Coefficients.tStat(idx); % read the t-stat
        df = mdl.Coefficients.DF(idx); % degrees of freedom
        d = round(2*abs(t)/sqrt(df),2); % this is actually a cohen's d using formula from Rosenthal and Rosnow, 1991
    end
end

function f2size = interpret_f2(f2,type)
% finding effect size using guidelines for interpretation of f2 indicating that 0.02 is a small effect, 0.15 is a medium effect, and 0.35 is a large effect (Cohen 1992)
f2size = 'dubious';
    switch type
        case {'Cohen''s f2'}
            if f2>=0.35
                f2size = 'large';
            elseif f2>=0.15
                f2size = 'medium';
            elseif f2>=0.02
                f2size = 'small';
            end
        case {'Cohen''s d'} % using Cohen's (1992) guidelines expanded by Sawilowsky (2009)
            if f2>=2
                f2size = 'huge';
            elseif f2>=1.2
                f2size = 'very large';
            elseif f2>=0.8
                f2size = 'large';
            elseif f2>=0.5
                f2size = 'medium';
            elseif f2>=0.2
                f2size = 'small';
            elseif f2>=0.01
                f2size = 'very small';
            end
        case {'None'}   % not calculated
            f2size = 'N/A'; 
        otherwise
            warning('unrecognized effect size type')
            f2size = 'N/A';
    end
end