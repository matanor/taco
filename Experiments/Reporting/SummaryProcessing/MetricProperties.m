classdef MetricProperties < handle
    
properties (Constant)
    ACCURACY  = ParamsManager.OPTIMIZE_BY_ACCURACY;
    PRBEP     = ParamsManager.OPTIMIZE_BY_PRBEP;
%     ParamsManager.OPTIMIZE_ALL_1 = 3;
    MRR       = ParamsManager.OPTIMIZE_BY_MRR;
    MACRO_MRR = ParamsManager.OPTIMIZE_BY_MACRO_MRR;
    MACRO_ACC = ParamsManager.OPTIMIZE_BY_MACRO_ACCURACY;
%     ParamsManager.OPTIMIZE_BY_LEVENSHTEIN = 7;
end % constant

methods (Static)

%% allMetricsRange

function R = allMetricsRange()
    R = [MetricProperties.PRBEP     MetricProperties.ACCURACY ...
         MetricProperties.MACRO_ACC MetricProperties.MRR ...
         MetricProperties.MACRO_MRR ];
end
    
%% metricKeys

function R = metricKeys()
    R{MetricProperties.PRBEP}     = 'avg PRBEP';
    R{MetricProperties.ACCURACY}  = 'avg accuracy';
    R{MetricProperties.MACRO_ACC} = 'avg macro accuracy';
    R{MetricProperties.MRR}       = 'avg MRR';
    R{MetricProperties.MACRO_MRR} = 'avg macro MRR';
end

%% metricShortNames

function R = metricShortNames()
    R{MetricProperties.PRBEP}     = 'PRBEP';
    R{MetricProperties.ACCURACY}  = 'Accuracy';
    R{MetricProperties.MACRO_ACC} = 'M-ACC';
    R{MetricProperties.MRR}       = 'MRR';
    R{MetricProperties.MACRO_MRR} = 'M-MRR';
end

%% metricOptimizeByName

function R = metricOptimizeByName()
    R{MetricProperties.PRBEP}     = 'PRBEP';
    R{MetricProperties.ACCURACY}  = 'accuracy';
    R{MetricProperties.MACRO_ACC} = 'macroACC';
    R{MetricProperties.MRR}       = 'MRR';
    R{MetricProperties.MACRO_MRR} = 'macroMRR';
end

end %static methods

end