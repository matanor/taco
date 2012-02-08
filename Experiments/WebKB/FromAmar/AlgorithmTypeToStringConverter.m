classdef AlgorithmTypeToStringConverter
methods (Static)
    function R = convert( algorithmType )
        table = [   {SingleRun.MAD,     MAD.name() }; ...
                    {SingleRun.CSSLMC,  CSSLMC.name()};
                    {SingleRun.CSSLMCF, CSSLMCF.name()} ];
        R = [];
        numEntries = size(table, 1);
        for table_entry_i=1:numEntries
            entryValue = table(table_entry_i,:);
            if entryValue{1} == algorithmType
                R = entryValue{2};
            end
        end
    end
end
    
end

