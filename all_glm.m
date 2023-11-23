function mdls = all_glm(model)
% This function tries to apply all combinations of factors to determine the best GLM (Generalized Linear Model) using model comparison.
% It needs a structure (model) containing the following fields:
%   model.solid_factors = {'name_of_factor_or_list'}; % a factor or a list of factors that are always included in the model (for the moment, works with only one - use '' for none)
%   model.liquid_factors =   {'name_factor1','name_factor2','name_factor1:name_factor2'}; %  a list of possible factors to be included, that can be removed if needed, and the interactions terms to explore
%   model.max_nb_factors = 5; % the maximal nb of factors to explore in the model - as a rule of thumb, you need ~10 datapoints for each
%   model.dv = 'dependent_variable'; % the name of the dependent variable
%   model.distribution = 'normal'; % its distribution among poisson, normal, gamma, inverse gaussian, binomial
%   model.data = data; % a table with the data
%   model.links = {'log', 'reciprocal','identity','-2','-3','probit','logit', 'loglog','comploglog'}; %  a list of possible link functions
% Example of use:
%           model.solid_factors = 'meditation';
%           model.liquid_factors = {'music','sport','expect','music:meditation','sport:meditation','expect:meditation'};
%           model.data = data;
%           model.max_nb_factors = 5;
%           model.warning_off = 1;
%           model.dv = 'initial_work_mem';
%           model.distribution = 'normal';
%           model.links = { 'identity'}; %   model.links = {'log', 'reciprocal','identity'};
%           model.exclude = [8,12];
%     mdls = all_glm(model);
%     display_model(mdls{1})
%     h=subplot(1,4,4); plot_group_effect(data.initial_work_mem, data.meditation, h, 'Meditation group', 'initial working memory performance', {'Meditators','Non-meditators'})
%     saveas(gcf,fullfile(figure_path,'working_memory_initial_glm.png')); 

if isempty(model.solid_factors); skip_solid = 1; else; skip_solid = 0; end
if isfield(model,'warning_off') || model.warning_off==1; warning('off','all'); end
if isfield(model,'exclude') ; exclude = 1; else; exclude = 0; end
if exclude % here I prefer to exclude the observations, rather than using the Exclude option in fitglm, otherwise, the excluded data are then wrongly reincorporated in the diagnostic plots.
   model.data(model.exclude,:) = []; 
end
rot_fact_nb = model.max_nb_factors - numel(model.solid_factors);
skip=0;
if skip_solid
    formula_start = [model.dv,' ~ 1'];
else
    formula_start = [model.dv,' ~ 1 + ',model.solid_factors{1}];
end
if rot_fact_nb>0 % generates a list of models with various liquid factors to test
    list_models = cell(1,1);
    n=1;
    for i=1:min(rot_fact_nb,numel(model.liquid_factors)) %correct max nb to nb of liquid factors
        list_models_nb = nchoosek(1:numel(model.liquid_factors),i);
        for j=1:size(list_models_nb,1) % each line is a permutation of factors
            list_models(n+(j-1),1) = {model.liquid_factors(list_models_nb(j,:))};
        end
        n=n+size(list_models_nb,1);
    end
else
    skip = 1;
    formulas = formula_start;
end

% generates the model formulas to test
if skip==0
    formulas = cell(size(list_models,1),1);
    for i=1:size(list_models,1)
        formula = formula_start;
        this_mdl = list_models{i};
        for j=1:numel(this_mdl)
            formula = [formula,' + ', this_mdl{j}];
        end
        formulas{i}= formula;
    end
end

% generates the possible link functions to test
model.links = cellfun(@get_distr,model.links,'UniformOutput',false);

% run all the models formulas into glm
mdls = cell(size(formulas,1)*numel(model.links),1);
mdl_formulas = mdls; mdl_links = mdls; mdl_aiccs = zeros(numel(mdls),1); mdl_r2_adj = zeros(numel(mdls),1); mdl_r2 = mdl_r2_adj; norm_res = mdls;
try
for i=1:size(formulas,1)
    for j=1:numel(model.links)
        idx = numel(model.links)*(i-1)+j;
        mdl = fitglm(model.data,formulas{i},'Distribution',model.distribution,'Link',model.links{j});
        mdls{idx} = mdl;
        mdl_formulas{idx} = formulas{i};
        mdl_links{idx} = model.links{j};
        mdl_aiccs(idx) = mdl.ModelCriterion.AICc;
        mdl_r2_adj(idx) = round(100.*mdl.Rsquared.Adjusted,1);
        mdl_r2(idx) = round(100.*mdl.Rsquared.Ordinary,1);
        if sum(isnan(mdl.Residuals.raw))==numel(mdl.Residuals.raw)
            %all values are nan, something went wrong
            norm_res{idx} = 'no';
        else
            H = kstest((mdl.Residuals.raw-nanmean(mdl.Residuals.raw))./nanstd(mdl.Residuals.raw));
            if H==1; norm_res{idx} = 'no'; else; norm_res{idx} = 'yes'; end
        end
    end
end
catch err
    keyboard
end
dispi('We tested ',numel(mdl_aiccs),' models.')
models = sortrows(table((1:numel(mdl_aiccs))',mdl_formulas,mdl_links,mdl_aiccs,mdl_r2_adj,mdl_r2,norm_res,'VariableNames',{'Rank','formula','link','AICc','adj.R2(%)','R2(%)','norm.res.'}),'AICc');
mdls = mdls(models.Rank); %reorder mdls so it is in the same order as models
models.Rank = (1:numel(mdl_aiccs))'; %make their rank increase too
disp(models)

end

function link = get_distr(linkn)
    switch linkn 
        case{'reciprocal','Reciprocal','inverse'}
            link = 'reciprocal';
        case{'identity','Identity'}
            link = 'identity';
        case{'log', 'Log','log10','ln','Log10','Ln'}
            link = 'log';
        case{'logit' , 'Logit'} 
            link = 'logit';
        case{'Probit' , 'probit'} 
            link = 'probit';
        case{'-2','inverse_square','reciprocal_square'}
            link = -2;
        case{'Loglog','loglog'}
            link = 'loglog';
    end
end
