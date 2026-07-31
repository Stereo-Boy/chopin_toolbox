function [h,p,stats] = wilcoxon_mann_whitney_format(x,y,header, varargin)
% Does a wilcoxon mann-whitney (rank-sum) test for two independant samples and formats the results, printing
% the header at the beginning on the command window. 
% All varargin are transfered to ranksum, following the same rules.
% Typical use: wilcoxon_mann_whitney_format(data(data.cond==1),data(data.cond==2),'cond 1 - cond 2 difference')

if any(strcmpi(varargin,'alpha')); i=find(strcmpi(varargin,'alpha')); alpha = varargin{i+1}; else; alpha = 0.05; end
if any(strcmpi(varargin,'tail')); i=find(strcmpi(varargin,'tail')); tail = varargin{i+1}; else; tail = 'both'; end
if ~exist('header','var'); header = ''; end

% making sure we have an array and not a table
if istable(x); x = table2array(x); end
if istable(y); y = table2array(y); end

%reshaping x and y so that row data are subjects
if size(x,2)>size(x,1); x=x'; end
if size(y,2)>size(y,1); y=y'; end

% removing any nan values
x = x(~isnan(x));
y = y(~isnan(y));

if numel(x)==0 || numel(y)==0; warning('wilcoxon_mann_whitney_format: something went wrong - no data left. Please check.'); h=[]; p=[]; stats=[]; return; end

%computing test
[p, h, stats] = ranksum(x,y,'alpha',alpha,'tail',tail);

%show formatted results
if strcmp(tail,'both'); tail_add=''; else;    tail_add = 'one-tailed ';  end
if p<0.0001
   dispi(header,' - ','Wilcoxon-Mann–Whitney (rank-sum)',tail_add,' U = ',sprintf('%.0f',stats.ranksum),', p = ',sprintf('%.6f',p))
else
   dispi(header,' - ','Wilcoxon-Mann–Whitney (rank-sum)',tail_add,' U = ',sprintf('%.0f',stats.ranksum),', p = ',sprintf('%.4f',p))   
end

