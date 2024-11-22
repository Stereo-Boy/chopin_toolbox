function table = adjust_p_benjamini_hochberg(table, additional_comparisons, force_nb_tests)
% Adjust p values and hypothesis test in the stat table provided by the function display_model, using the Benjamini Hochberg procedure, and display it.
%
% table is the stat table provided by the function display_model and should at least contain the column pValue
% optional additional_comparisons: a number reflecting how many other comparisons have been already tested before, as part of a primary hypothesis test structure for example, but not included in the table here
% optional force_nb_tests - forces an actual nb of tests to correct from the table (if not provided, default is the number of lines in table). Note that additional_comparisons would still be added to that number.
% Be cautious when using that argument (see below).
%
% Typical use:
% table_stats_1 = display_model(mdls1{1}); % 2 tests
% table_stats_2 = display_model(mdls2{1}); % 3 tests
% model.tests = 4; % actually only retain 4 of these tests as relevant for the hypotheses (careful with that option)
% table = adjust_p_benjamini_hochberg([table_stats_1; table_stats_2], 1, model) % also add 1 additional earlier test (total 5)
% 
% Output: a table with each factor ranked from best to worst p value, its stats, DF, initial pvalue, adjusted p-value (equivalent to an alpha threshold of 0.05), or adjusted alpha to compare initial p-value to,
% and whether to reject or not H0
%
% Caution with force_nb_tests: if you force a lower nb of tests to correct for, and that the tests that you wanted to ignore have good p-value, they can take the spots of one of your critical tests and render the
% adjustment incorrect. Use only if the tests to be ignored have bad enough p-values. A better practice would be to remove the tests that you want to ignore from the input table.

try
if ~exist('force_nb_tests','var') || isempty(force_nb_tests); force_nb_tests = size(table,1); end
if ~exist('table','var') || ~ismember('pValue',table.Properties.VariableNames); disp('[adjust_p_benjamini_hochberg: incorrect table provided - exiting.]'); return; end
if ~exist('additional_comparisons','var') || isempty(additional_comparisons); additional_comparisons = 0; end

% adjusting the nb of comparisons to reflect potential past comparisons
force_nb_tests =  force_nb_tests + additional_comparisons;
 
disp('Adjustment for multiple comparisons: method of Benjamini-Hochberg')

% reorder the factors by increasing p values
[~,idx]=sort(table.pValue);
table = table(idx,:);

% define thresholds
alpha = 0.05;
H0_reject = zeros(size(table,1),1); % hypotheses rejection (1)
adj_alpha = ones(size(table,1),1).*alpha; % values of adjusted alphas

first_no_reject = 0; % as soon as one hypothesis is not rejected, the larger p-values are also rejected
for i=1:size(table,1)
    % apply p adjustment
    adj_alpha(i) = i.*alpha./force_nb_tests;
    if table.pValue(i)<=adj_alpha(i) && first_no_reject == 0
        H0_reject(i) = 1;
    else
        first_no_reject = 1;
    end
end
table.adj_alpha = adj_alpha;
table.adj_pValue = min(1,table.pValue.*alpha./adj_alpha);
table.H0_reject = H0_reject;

% show the results
disp(table)
for j=1:size(table,1)
    if table.H0_reject(j) == 1 %reject
        result = 'Significant';
    else
        result = 'No significant';
    end
    if ismember('Name',table.Properties.VariableNames) && ismember('DF',table.Properties.VariableNames) && ismember('tStat',table.Properties.VariableNames)
        dispi(result,' effect of ',table.Name{j},' (t(',table.DF(j),') = ',round(table.tStat(j),2),', adjusted p = ',round(table.adj_pValue(j),4),')')
    end
end
catch err
    disp('Something went wrong: now in debugging mode if you need to troubleshoot (write rethrow(err) to see what''s the error).')
    keyboard
end