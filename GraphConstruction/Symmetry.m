classdef Symmetry
    
methods (Static)

    %% makeSymetric
    %  Get a matrix of weights and make it symmetric.

    function weights = makeSymetric(weights)
        if Symmetry.isSymetric( weights )
            Logger.log('Symmetry::makeSymetric. input already summetric. skipping..');
            return;
        end
        if ( issparse(weights) )
            weights = Symmetry.sparse_makeSymetric(weights);
        else
            weights = Symmetry.dense_makeSymetric(weights);
        end
    end
    
    %% dense_makeSymetric
    
    function w_out = dense_makeSymetric( w )
        w_size = size(w,1);
        for row_i=1:w_size
            for  col_i=1:w_size
                value = w(row_i, col_i);
                if ( value ~= 0)
                    sym_value = w( col_i, row_i );
                    if (sym_value == 0)
                        w( col_i, row_i ) = value;
                    elseif (sym_value ~= value )
                        Logger.log(['Symetry::dense_makeSymetric. error in'...
                                    ' row_i = ' num2str(row_i) ...
                                    ' col_i = ' num2str(col_i) ...
                                    ' value = ' num2str(value) ...
                                    ' sym_value = ' num2str(sym_value) ...
                                    '. sym_value expected to be 0.']);
                    end
                end
            end
        end

        w_out = w;
    end

    %% sparse_makeSymetric

    function weights = sparse_makeSymetric(weights)
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
       A_sym_dense = Symmetry.makeSymetric(A);
       A = sparse(A);
       A_sym_sparse = full( Symmetry.makeSymetric(A) );
       assert( Symmetry.isSymetric( A_sym_dense ) );
       assert( Symmetry.isSymetric( A_sym_sparse ) );
       assert( isequal( A_sym_dense, A_sym_sparse ) );
   end

end
    
end



