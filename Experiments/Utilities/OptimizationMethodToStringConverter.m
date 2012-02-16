classdef OptimizationMethodToStringConverter
methods (Static)
    function R = convert( optimizationMethod )
        table = [   {ParamsManager.OPTIMIZE_BY_ACCURACY, 'accuracy' }; ...
                    {ParamsManager.OPTIMIZE_BY_PRBEP,    'PRBEP'} ];
                
        R = EnumToStringConverter.convert(table, optimizationMethod);
    end
end
    
end
