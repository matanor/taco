classdef AlgorithmTypeToStringConverter
methods (Static)
    function R = convert( algorithmType )
        table = [   {SingleRun.MAD,     MAD.name() }; ...
                    {SingleRun.CSSLMC,  CSSLMC.name()};
                    {SingleRun.CSSLMCF, CSSLMCF.name()} ];
                
        R = EnumToStringConverter.convert(table, algorithmType);
    end
end
    
end

