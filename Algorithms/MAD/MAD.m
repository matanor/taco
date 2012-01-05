classdef MAD < handle
    properties (Access=public)
    end
    
    methods(Static)
        function r = name()
            r = 'MAD';
        end
    end
    
    methods (Access=public)
        function    Yout = run( this, W, Y, params, labeledVertices )
            %MAD Modified ADsorption
            %   W - graph weights
            %   Y - prior labeling, its size should be
            %        number of vertices X number of labels.
            %   params - a structure containing:
            %               mu1
            %               mu2
            %               mu3
            %               numIterations
            % Reference: New regularized algorithms for transductive learning
            % Talukdar, P. and Crammer, Koby. pages 10.

            tic;

            mu1 = params.mu1;
            mu2 = params.mu2;
            mu3 = params.mu3;
            numIterations = params.numIterations;

            numVertices = size(W, 1);

            disp('Calculating probabilities...');
            p = MAD.calcProbabilities(W, labeledVertices);
            disp('done');

            % add dummy label. initialy no vertex is
            % associated with the dummy label.
            Y = [Y zeros(numVertices, 1) ];
            numLabels = size( Y, 2 );

            % Line (2) of MAD page 10 in reference 

            disp('Calculating M(v)...');
            M = MAD.calcM(W, p, params);
            disp('done');

            D = zeros( size(Y) );
            r = zeros(numLabels, 1);
            r(end) = 1;

            for iter_i=1:numIterations

                if ( mod(iter_i, 10) == 0 )
                    disp(['#Iteration = ' num2str(iter_i)]);
                end

                % line (4) of MAD page 10 in reference 
                for vertex_i=1:numVertices
                    Dv = MAD.calcDv(W, p, Y, vertex_i);
                    D( vertex_i, :) = Dv.';
                end

                % lines (5)-(6)-(7) of MAD page 10 in reference 
                for vertex_i = 1:numVertices
                    p_inject   = p.inject(vertex_i); 
                    p_abandon  = p.abandon(vertex_i); 

                    Yv = Y( vertex_i, : ).';
                    Dv = D( vertex_i, : ).';
                    Mv = M( vertex_i );
                    Yv = (1/Mv) * ...
                         (mu1 * p_inject * Yv + ... 
                          mu2 * Dv + ...
                          mu3 * p_abandon * r);
                    Y(vertex_i,:) = Yv .';
                end
            end

            Yout = Y;

            toc;
        end
    end %     methods (Access=public)
    
    methods(Static)
        function Dv = calcDv( W, p, Y, vertex_i )
            %CALCDV Summary of this function goes here
            %   Detailed explanation goes here

            neighbours = getNeighbours(W, vertex_i);
            p_continue = p.continue(vertex_i); 

            numLabels = size( Y, 2 );
            Dv = zeros( numLabels, 1);

            numNeighbours = length(neighbours.indices);
            for neighbour_i=1:numNeighbours
                neighbour_weight = neighbours.weights(neighbour_i);
                neighbour_id    = neighbours.indices(neighbour_i);
                outgoing = neighbour_weight;
                incoming = W(neighbour_id, vertex_i);
                p_continue_neighbour = p.continue(neighbour_id);
                avg_weight = p_continue * outgoing + ...
                             p_continue_neighbour * incoming;
                Y_neighbour = Y( neighbour_id, : ).';
                Dv = Dv + avg_weight * Y_neighbour;
            end
        end
        
        function M = calcM( W, p, params )
            %CALCM Summary of this function goes here
            %   Detailed explanation goes here

            mu1 = params.mu1;
            mu2 = params.mu2;
            mu3 = params.mu3;

            numVertices = size(W, 1);
            M = zeros( numVertices, 1);

            for vertex_i=1:numVertices
                p_inject   = p.inject(vertex_i); 
                p_continue = p.continue(vertex_i); 
                neighbours = getNeighbours(W, vertex_i);

                numNeighbours = length(neighbours.indices);
                sumNeighbours = 0;
                for neighbour_i=1:numNeighbours
                    neighbour_weight = neighbours.weights(neighbour_i);
                    neighbour_idx    = neighbours.indices(neighbour_i);
                    outgoing = neighbour_weight;
                    incoming = W(neighbour_idx, vertex_i);
                    p_continue_neighbour = p.continue(neighbour_idx);
                    sumNeighbours = sumNeighbours + ...
                                    p_continue * outgoing + ...
                                    p_continue_neighbour * incoming;
                end
                M (vertex_i) =  mu1 * p_inject + ...
                                mu2 * sumNeighbours + ...
                                mu3;
            end
        end
        
        function p = calcProbabilities( W, labeledVertices )
            %CALCPROBABILITIES Calculate continue, injection and abandon
            % probabilities for each vertex. 
            % Reference: New regularized algorithms for transductive learning
            % Talukdar, P. and Crammer, Koby. pages 4-5.

            numVertices = size(W,  1);
            p.inject    = zeros(numVertices, 1);
            p.continue  = zeros(numVertices, 1);
            p.abandon   = zeros(numVertices, 1);
            beta = 2;
            for vertex_i=1:numVertices
                neighbours = getNeighbours( W, vertex_i );
                transitions = MAD.calcTransitions( neighbours.weights );
                entropy = - sum( transitions .* log(transitions) );
                % use log2 ad done is scala code downloaded from http://talukdar.net/
                %cv = log(beta) / log2( beta + exp( entropy) ) ;
                cv = log(beta) / log2( beta + entropy ) ;
                isLabeled = ismember( vertex_i, labeledVertices );
                dv = isLabeled * (1-cv) * sqrt( entropy ) ;
                zv = max( cv + dv, 1 );
                p.continue(vertex_i) = cv / zv;
                p.inject  (vertex_i) = dv / zv;
                p.abandon (vertex_i) = 1 - p.continue(vertex_i) - ...
                                       p.inject  (vertex_i);
            end
        end
        
        function transitions = calcTransitions(neighboursWeigths )
            %CALCTRANSITIONS Calculate transition probabilitis from neighbours weights
            %   Detailed explanation goes here

            s = sum( neighboursWeigths );
            transitions = neighboursWeigths / s;
        end
        
    end % methods(Static)
end

