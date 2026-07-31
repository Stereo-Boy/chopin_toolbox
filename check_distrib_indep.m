function check_distrib_indep(dataGroup1, dataGroup2, header)
% This function works for one or two independent groups
% If one group: checks normality and plots distribution
% If two groups: tests for difference, pools if not different, plots both
% If the data are not normally distributed, it will attempt to transform in log

if ~exist('header','var'); header = ''; end
if ~exist('dataGroup2','var') || isempty(dataGroup2)
    twoGroups = false;
else
    twoGroups = true;
end

% first remove missing data
dataGroup1 = rmmissing(dataGroup1);
if twoGroups
    dataGroup2 = rmmissing(dataGroup2);
    data = [dataGroup1; dataGroup2];
else
    data = dataGroup1;
end
minn = min(data);
maxx = max(data);

figure('Color', 'w', 'units','normalized','outerposition',[0 0 1 1]);

if twoGroups
    h = wilcoxon_mann_whitney_format(dataGroup1, dataGroup2, header);
    subplot(2,3,1); hist(dataGroup1); title('Group 1'); xlabel(header); xlim([minn maxx]);
    subplot(2,3,2); hist(dataGroup2); title('Group 2'); xlabel(header); xlim([minn maxx]);
    if h==0
        disp('Data are not significantly different, so let''s group them')
        [H1, P1, KSstat1] = kstest(zscore(data)); H2 = 0;
        dispi('Kolmogorov-Smirnov test for normality:  KS = ',sprintf('%.2f',KSstat1),', p = ',sprintf('%.4f',P1));
        subplot(2,3,3); hist(data); title('All groups'); xlabel(header); xlim([minn maxx]);
    else
        disp('Data are significantly different, so let''s keep them separated')
        [H1, P1, KSstat1] = kstest(zscore(dataGroup1)); [H2, P2, KSstat2] = kstest(zscore(dataGroup2));
        dispi('Kolmogorov-Smirnov tests for normality:  Group 1 - KS = ',sprintf('%.2f',KSstat1),', p = ',sprintf('%.4f',P1), ...
            ' and Group 2 - KS = ',sprintf('%.2f',KSstat2),', p = ',sprintf('%.4f',P2));
    end
else
    h = 0; % no group comparison needed
    subplot(2,3,1); hist(dataGroup1); title('Data'); xlabel(header); xlim([minn maxx]);
    [H1, P1, KSstat1] = kstest(zscore(data)); H2 = 0;
    dispi('Kolmogorov-Smirnov test for normality:  KS = ',sprintf('%.2f',KSstat1),', p = ',sprintf('%.4f',P1));
end

log_data = log10(data);
minn_log = min(log_data);
maxx_log = max(log_data);

if ((H1==1) || (H2==1)) && (~any(data<=0))
    try
        disp('Data are non-normal so let''s try to log-transform the data')
        if twoGroups
            subplot(2,3,4); hist(log10(dataGroup1)); title('Group 1 log-transformed'); xlabel(header); xlim([minn_log maxx_log]);
            subplot(2,3,5); hist(log10(dataGroup2)); title('Group 2 log-transformed'); xlabel(header); xlim([minn_log maxx_log]);
            if h==0
                subplot(2,3,6); hist(log_data); title('All groups log-transformed'); xlabel(header); xlim([minn_log maxx_log]);
                [H1, P1, KSstat1] = kstest(zscore(log_data)); H2 = 1;
                dispi('Kolmogorov-Smirnov test for normality:  KS = ',sprintf('%.2f',KSstat1),', p = ',sprintf('%.4f',P1));
            else
                [H1, P1, KSstat1] = kstest(zscore(log10(dataGroup1))); [H2, P2, KSstat2] = kstest(zscore(log10(dataGroup2)));
                dispi('Kolmogorov-Smirnov tests for normality:  Group 1 - KS = ',sprintf('%.2f',KSstat1),', p = ',sprintf('%.4f',P1), ...
                    ' and Group 2 - KS = ',sprintf('%.2f',KSstat2),', p = ',sprintf('%.4f',P2));
            end
        else
            subplot(2,3,4); hist(log_data); title('Data log-transformed'); xlabel(header); xlim([minn_log maxx_log]);
            [H1, P1, KSstat1] = kstest(zscore(log_data));
            dispi('Kolmogorov-Smirnov test for normality:  KS = ',sprintf('%.2f',KSstat1),', p = ',sprintf('%.4f',P1));
        end
    catch err
        warning('check_distrib_indep: could not do log transform: likely 0 or negative data.')
        keyboard
    end
end