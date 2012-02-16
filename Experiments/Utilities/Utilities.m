classdef Utilities
    %UTILITIES Summary of this class goes here
    %   Detailed explanation goes here
    
properties
end
    
methods (Static)
    
    %% StructToStringConverter
    
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
    
    %% test_StructToStringConverter
    
    function test_StructToStringConverter()
        s.f1 = 1;
        s.f2 = [ 1 2 ];
        s.f3 = 'abc';
        s.f4 = {'abc'};
        x = Utilities.StructToStringConverter(s);
        disp(x);
    end
    
    %% combineStructs
    
    function R = combineStructs(A, B)
%http://stackoverflow.com/questions/38645/what-are-some-efficient-ways-to-combine-two-structures-in-matlab
        M = [fieldnames(A)' fieldnames(B)'; ...
             struct2cell(A)' struct2cell(B)'];
        R = struct(M{:});
    end
    
    %% combineStructs_removeDuplicates
    
    function R = combineStructs_removeDuplicates(A,B)
        M = [fieldnames(A)' fieldnames(B)'; struct2cell(A)' struct2cell(B)'];

        [~, rows] = unique(M(1,:), 'last');
        M=M(:, rows);

        R=struct(M{:});
    end
    
    %% test_combineStructs
    
    function test_combineStructs()
        s1.f1 = 1;
        s1.f2 = 'abc';
        s2.f3 = 56;
        s2.f5 = {123};
        R = Utilities.combineStructs(s1, s2);
    end
    
    %% printCommaSeperatedMatrix
    
    function printCommaSeperatedMatrix( M )
        SEPERATOR = ',';
        [numRows numCols] = size(M);
        for row=1:numRows
            rowString = num2str(M(row,1));
            for col=2:numCols
                rowString = [rowString ...
                             SEPERATOR num2str(M(row,col))]; %#ok<AGROW>
            end
            disp(rowString);
        end
    end
    
end
    
end

