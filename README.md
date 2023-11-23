# chopin toolbox
A toolbox mostly for statistical models and formating.

## Description
The toolbox contains various handy functions for manipulating files and data, more 'serious' functions for automatical stastistical analyses, a few stat tools and other handy functions for automatically plotting the data.

## Getting Started
### Dependencies
* Tested on Matlab R2020b
* Tested on Windows 11 pro but should work cross-platforms

### Installing
* download the code
* add its containing folder to your matlab search path

## Content
### Automated GLM (generalized) pipeline
The following functions are used together to easily separate model selection from statistics. 
* all_glm automatically tests and ranks all GLMs as combinations of factors/interactions of factors/link functions
* display_model formats the results in the command window
* plot_group_effect/plot_covariate_effect plots the results easily

Typical use:
```matlab
% first define a model structure 
    model.solid_factors = {'name_of_factor_or_list'}; % a factor or a list of factors that are always included in the model (for the moment, works with only one - use '' for none)
    model.liquid_factors =   {'name_factor1','meditation','name_factor1:name_factor2'}; %  a list of possible factors to be included, that can be removed if needed, and the interactions terms to explore
    model.max_nb_factors = 5; % the maximal nb of factors to explore in the model - as a rule of thumb, you need ~10 datapoints for each
    model.dv = 'initial_work_mem'; % the name of the dependent variable in the data structure, here it is data.initial_work_mem
    model.distribution = 'normal'; % its distribution among poisson, normal, gamma, inverse gaussian, binomial
    model.data = data; % a table with the data, here called data
    model.warning_off = 1; % no warnings - careful with that option
    model.links = {'log', 'identity'}; %  a list of possible link functions among 'log', 'reciprocal','identity','-2','-3','probit','logit','loglog','comploglog'
    model.exclude = [8,12]; % outliers/subjects to be removed

% run the model
mdls = all_glm(model);

% display diagnostics and results
display_model(mdls{1}) %plot best model - you can select any other models according to the results on the various indicators provided
h=subplot(1,4,4);

% add plots of results and save figures
plot_group_effect(data.initial_work_mem, data.meditation, h, 'Meditation group', 'initial working memory performance', {'Meditators','Non-meditators'})
saveas(gcf,fullfile(figure_path,'initial working memory.png'));
snapnow; %plot figure when publishing markup code
```

## Authors
Adrien Chopin, 2023
The code is mostly made of codes from other people:
* Bayes Factor from Bart Krekelberg
* Cohen's D from Ruggero G. Bettinardi (RGB) / Cellular & System Neurobiology, CRG
* Shapiro test from Gardner-O'Kearny, William (2021). swft - Shapiro-Wilk/Shapiro-Francia Tests (https://www.mathworks.com/matlabcentral/fileexchange/<...>), MATLAB Central File Exchange. Retrieved March 13, 2021.
* Justin Theiss for check_files / check_folders functions
* sumsqr from Mark Beale, 1-31-92 / Copyright 1992-2017 The MathWorks, Inc.
  
## Version History
* Current version is 1.0
* Version 1.0 includes various handy functions for manipulating files and data, more 'serious' functions for automatical stastistical analyses, a few stat tools and other handy functions for automatically plotting the data.

## License
This project is licensed under the MIT License - see the LICENSE.md file for details.
To use it you may also follow any license for borrowed codes (see Authors section).
