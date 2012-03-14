classdef OptimizationMethodToStringConverter
methods (Static)
    function R = convert( optimizationMethod )
        table = [   {ParamsManager.OPTIMIZE_BY_ACCURACY, 'accuracy' }; ...
                    {ParamsManager.OPTIMIZE_BY_PRBEP,    'PRBEP'};...
                    {ParamsManager.OPTIMIZE_ALL_1,       'unoptimized'};...
                    {ParamsManager.OPTIMIZE_BY_MRR,      'MRR'}];
                
        R = EnumToStringConverter.convert(table, optimizationMethod);
    end
end
    
end
