classdef EnumToStringConverter
methods (Static)
    function R = convert( table, value)
        R = [];
        numEntries = size(table, 1);
        for table_entry_i=1:numEntries
            entryValue = table(table_entry_i,:);
            if entryValue{1} == value
                R = entryValue{2};
            end
        end
    end
end
    
end

