classdef Symmetry
    
methods (Static)

    %% makeSymetric

    function weights = makeSymetric(weights)
        if Symmetry.isSymetric( weights )
            Logger.log('Symmetry::makeSymetric. input already summetric. skipping..');
            return;
        end
        [rows,cols,values] = find(weights);
        [numRows numCols] = size(weights);
        allRows     = [rows;cols];
        allColumns  = [cols;rows];
        allValues   = [values;values];

        indices = [allRows allColumns];
        [uniqueIndices, usedRows,~] = unique(indices, 'rows');
        uniqueValues = allValues(usedRows);
        uniqueRows = uniqueIndices(:,1);
        uniqueCols = uniqueIndices(:,2);

        weights = sparse(uniqueRows, uniqueCols, ...
                         uniqueValues, numRows, numCols);
    end

   %% isSymetric
   %  Checks if the matrix <X> is symetric.
   
   function result = isSymetric( X )
        result = isequal(X,X.');
   end
    
   %% testMakeSymetric
    
   function testMakeSymetric()
       A = [1 2 3; 0 0 0; 0 0 0];
       A = sparse(A);
       sym = Symmetry.makeSymetric(A);
       A_sym = full(sym);
       assert( Symmetry.isSymetric( A_sym ) );
   end

end
    
end



