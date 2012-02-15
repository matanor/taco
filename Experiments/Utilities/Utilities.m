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
            fieldValue = struct.( fieldName );
            if numel(fieldValue) == 1 && ~iscell(fieldValue)
                fieldValueString = num2str( fieldValue );
                s = [s fieldName ' = ' fieldValueString ' ' ]; %#ok<AGROW>
            end
        end
    end
    
    function test_StructToStringConverter()
        s.f1 = 1;
        s.f2 = [ 1 2 ];
        s.f3 = 'abc';
        s.f4 = {'abc'};
        x = Utilities.StructToStringConverter(s);
        disp(x);
    end
end
    
end

