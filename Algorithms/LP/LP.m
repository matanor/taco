classdef LP < handle
    methods(Static)
        function r = name()
            r = 'LP';
        end
        function result = run( W, labeledPositive, labeledNegative )
            %LABELPROPAGATION Label Propagation SSL algorithm
            %   Detailed explanation goes here

            numVertices = size(W, 1);
            Y = zeros(numVertices, 1);

            positiveInitialValue = +1;
            negativeInitialValue = -1;

            Y( labeledPositive ) = positiveInitialValue;
            Y( labeledNegative ) = negativeInitialValue;

            D = zeros(numVertices, 1);
            for vertex_i=1:numVertices
                neighbours = getNeighbours( W, vertex_i );
                D(vertex_i) = sum(neighbours.weights);
            end

            D_inv = 1 ./ D;
            D_inv_matrix = diag(D_inv);

            finished = 0;
            diff_epsilon = 0.01;
            iter_i = 1;
            while ( 0 == finished)
                Y_t_plus1 = D_inv_matrix * W * Y;
                Y_t_plus1( labeledPositive ) = positiveInitialValue;
                Y_t_plus1( labeledNegative ) = negativeInitialValue;
                diff = norm( Y - Y_t_plus1 , 2);
                if diff < diff_epsilon
                    finished = 1;
                end
                Y = Y_t_plus1;
                iter_i = iter_i + 1;
            end

            result = Y;
        end
    end % methods(Static)    
end % classdef
