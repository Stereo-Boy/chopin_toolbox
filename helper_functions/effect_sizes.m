function effect_sizes_table = effect_sizes(mdl, model)
% Calculate local Cohen's f2 (f squared) for mixed effect model following the rational in 
% Selya et al. (2012) - A Practical Guide to Calculating Cohents f2, a Measure of Local Effect Size, from PROC MIXED.
% It will output the local effect size for each of the fixed effect factors in model
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
% first create a list of fixed factors
list_factors = split_factors(mdl.Formula);

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

% now loop through the list to create a model without the factor and extract its Rsquared
f2s = nan(size(list_factors)); f2sizes = cell(size(list_factors));
if numel(list_factors)>1
    for i=1:numel(list_factors)
        factor = list_factors{i};
        model.solid_factors = list_factors(~cellfun(@(x) strcmp(x,list_factors{i}), list_factors)); % select all factors but the ith one
        mdls = all_glm(model,0); % run the model with verbose off
        f2s(i) = round((mdl.Rsquared.Ordinary - mdls{1}.Rsquared.Ordinary)/(1-mdl.Rsquared.Ordinary),2);
        f2sizes = interpret_f2(i, f2s, f2sizes);
        dispi('Local effect size for ',factor,' : Cohen''s f2 = ',f2s(i),' (',f2sizes{i},')')
    end
else
    % when there is only one factor, we just calculate the model f2
    f2s(1) = mdl.Rsquared.Ordinary/(1-mdl.Rsquared.Ordinary);
    f2sizes(1) = interpret_f2(1, f2s, f2sizes);
    dispi('Local effect size for ',list_factors{1},' : Cohen''s f2 = ',f2s(1),' (',f2sizes{1},')')
end
effect_sizes_table = table(list_factors',f2s',f2sizes','VariableNames',{'Factor','f2','Interpretation'});

catch err
    disp('Error caught: for debugging, write rethrow(err)')
    keyboard
end
end

function terms = split_factors(formula)
% Split the formula into terms
    
    % first convert the model class in string
    formula = char(formula);

     % remove '~' and leading/trailing spaces
    terms = strsplit(formula, '~');
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

function f2sizes = interpret_f2(i, f2s, f2sizes)
% finding effect size using guidelines for interpretation of f2 indicating that 0.02 is a small effect, 0.15 is a medium effect, and 0.35 is a large effect (Cohen 1992)
        if f2s(i)>=0.35
            f2sizes{i} = 'large';
        elseif f2s(i)>=0.15
            f2sizes{i} = 'medium';
        elseif f2s(i)>=0.02
            f2sizes{i} = 'small';
        else
            f2sizes{i} = 'dubious';
        end
end