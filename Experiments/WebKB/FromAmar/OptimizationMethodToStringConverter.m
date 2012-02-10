classdef OptimizationMethodToStringConverter
methods (Static)
    function R = convert( optimizationMethod )
        table = [   {ParamsManager.OPTIMIZE_BY_ACCURACY, 'OptimizeByAccuracy' }; ...
                    {ParamsManager.OPTIMIZE_BY_PRBEP,    'OptimizeByPRBEP'} ];
                
        R = EnumToStringConverter.convert(table, optimizationMethod);
    end
end
    
end
