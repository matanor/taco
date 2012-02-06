classdef Utilities
    %UTILITIES Summary of this class goes here
    %   Detailed explanation goes here
    
properties
end
    
methods (Static)
    function s = StructToStringConverter( struct )
        f = fieldnames( struct );
        s = [];
        for i=1:numel(f)
            fieldName = f{i};
            fieldValue = num2str( struct.( fieldName ));
            s = [s fieldName ' = ' fieldValue ' ' ]; %#ok<AGROW>
        end
    end
end
    
end

