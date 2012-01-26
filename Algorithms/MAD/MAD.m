classdef MAD < handle
    properties (Access=public)
    end
    
    methods(Static)
        function r = name()
            r = 'MAD';
        end
    end
    
    methods (Access=public)
        function    result = run( this, W, Y, params, labeledVertices )
            %MAD Modified ADsorption
            %   W - graph weights
            %   Y - prior labeling, its size should be
            %        number of vertices X number of labels.
            %   params - a structure containing:
            %               mu1
            %               mu2
            %               mu3
            %               maxIterations - maximal number of iterations
            %               useGraphHeuristics - modify the graph
            %               by using heuristics (boolean)
            % Reference: New regularized algorithms for transductive learning
            % Talukdar, P. and Crammer, Koby. pages 10.

            tic;

            mu1 = params.mu1;
            mu2 = params.mu2;
            mu3 = params.mu3;
            useGraphHeuristics = params.useGraphHeuristics;
            maxIterations = params.maxIterations;
            
            paramsString = ...
                [' useGraphHeuristics = ' num2str(useGraphHeuristics) ...
                 ' maximum iterations = ' num2str(maxIterations)];                
            disp(['Running MAD.' paramsString]);

            numVertices = size(W, 1);

            disp('Calculating probabilities...');
            if (useGraphHeuristics ~=0)
                p = MAD.calcProbabilities(W, labeledVertices);
            else
                p = MAD.constantProbabilities(numVertices);
            end
            result.p = p;
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

            Y_hat = Y;
            result.Y(:,:,1) = Y_hat;
            
            iteration_diff = 10^1000;
            diff_epsilon = 0.00001;
            
            % note iteration index starts from 2
            for iter_i=2:maxIterations

                if iteration_diff < diff_epsilon
                    disp(['converged after ' num2str(iter_i) ' iterations']);
                    break;
                end
                
                if ( mod(iter_i, 10) == 0 )
                    disp([  '#Iteration = '      num2str(iter_i)...
                            ' iteration_diff = ' num2str(iteration_diff)]);
                end

                % line (4) of MAD page 10 in reference 
                for vertex_i=1:numVertices
                    Dv = MAD.calcDv(W, p, Y_hat, vertex_i);
                    D( vertex_i, :) = Dv.';
                end

                Y_hat_pre = Y_hat;
                % lines (5)-(6)-(7) of MAD page 10 in reference 
                for vertex_i = 1:numVertices
                    p_inject   = p.inject(vertex_i); 
                    p_abandon  = p.abandon(vertex_i); 

                    Yv = Y( vertex_i, : ).';
                    Dv = D( vertex_i, : ).';
                    Mv = M( vertex_i );
                    Yv_hat = (1/Mv) * ...
                         (mu1 * p_inject * Yv + ... 
                          mu2 * Dv + ...
                          mu3 * p_abandon * r);
                    Y_hat(vertex_i,:) = Yv_hat .';
                end
                iteration_diff = sum((Y_hat_pre(:) - Y_hat(:)).^2);
                result.Y(:,:,iter_i) = Y_hat;
            end

            toc;
        end
    end %     methods (Access=public)
    
    methods(Static)
        function Dv = calcDv( W, p, Y_hat, vertex_i )
            %CALCDV Summary of this function goes here
            %   Detailed explanation goes here

            neighbours = getNeighbours(W, vertex_i);
            p_continue = p.continue(vertex_i); 

            numLabels = size( Y_hat, 2 );
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
                Y_neighbour = Y_hat( neighbour_id, : ).';
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
                cv = log2(beta) / log2( beta + exp( entropy) ) ;
                %cv = log(beta) / log2( beta + entropy ) ;
                isLabeled = ismember( vertex_i, labeledVertices );
                dv = isLabeled * (1-cv) * sqrt( entropy ) ;
                zv = max( cv + dv, 1 );
                p.continue(vertex_i) = cv / zv;
                p.inject  (vertex_i) = dv / zv;
                p.abandon (vertex_i) = 1 - p.continue(vertex_i) - ...
                                       p.inject  (vertex_i);
            end
        end
        
        function p = constantProbabilities(numVertices)
            % Set to 1, so the parameter mu1 will control
            % injection
            p.inject    = ones(numVertices, 1);
            % MAD changed graph weights by multiplying each edge
            % W'_{i,j} = W_{i,j} * (p_cont_{i} + p_cont_{j})
            % set them both to 0.5 to remove influence.
            p.continue  = 0.5 * ones(numVertices, 1);
            % no dummy label.
            p.abandon   = zeros(numVertices, 1);
        end
        
        function transitions = calcTransitions(neighboursWeigths )
            %CALCTRANSITIONS Calculate transition probabilitis from neighbours weights

            s = sum( neighboursWeigths );
            transitions = neighboursWeigths / s;
        end
        
    end % methods(Static)
end

