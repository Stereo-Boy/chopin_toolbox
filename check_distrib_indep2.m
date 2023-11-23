function check_distrib_indep2(dataGroup1, dataGroup2, header)
% This function works for two independent groups dataGroup1 and dataGroup2
% 1. check for difference between groups using a non-paramatric test
% 2. if not different, group data, otherwise keep separated
% 3. plot distributions (if not grouped, group 1 is on line 1, group 2 on line 2
% 4. check for normality of the distribution using Kolmogorov-Smirnov test
% The header should be the name of the dependent variable.

% this variation always shows the pooled distribution as if we skipped step 1
if ~exist('header','var'); header = ''; end

data = [dataGroup1;dataGroup2];
minn = min(data);
maxx = max(data);

h = wilcoxon_mann_whitney_format(dataGroup1,dataGroup2,header);
figure('Color', 'w', 'units','normalized','outerposition',[0 0 1 1]);
subplot(2,3,1); hist(dataGroup1); title('Group 1'); xlabel(header); xlim([minn maxx]);
subplot(2,3,2); hist(dataGroup2); title('Group 2'); xlabel(header); xlim([minn maxx]);


    disp('Data are not significantly different, so let''s group them')
    [H1, P1, KSstat1] = kstest(zscore(data)); H2 = 0;
        dispi('Kolmogorov-Smirnov test for normality:  KS = ',sprintf('%.2f',KSstat1),', p = ',sprintf('%.4f',P1));
        subplot(2,3,3); hist(data); title('All groups'); xlabel(header); xlim([minn maxx]);


log_data = log10(data);
minn_log = min(log_data);
maxx_log = max(log_data);
    
if (H1==1) || (H2==1) %if any distribution is non-normal, try also to log-transform the data
    disp('Data are non-normal so let''s try to log-transform the data')
    subplot(2,3,4); hist(log10(dataGroup1)); title('Group 1 log-transformed'); xlabel(header); xlim([minn_log maxx_log]);
    subplot(2,3,5); hist(log10(dataGroup2)); title('Group 2 log-transformed'); xlabel(header); xlim([minn_log maxx_log]);

        subplot(2,3,6); hist(log_data); title('All groups log-transformed'); xlabel(header); xlim([minn_log maxx_log]);
        [H1, P1, KSstat1] = kstest(zscore(log_data)); H2 = 1;
        dispi('Kolmogorov-Smirnov test for normality:  KS = ',sprintf('%.2f',KSstat1),', p = ',sprintf('%.4f',P1));

end


