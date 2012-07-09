classdef MAD < GraphTrunsductionBase
    properties (Access=public)
        m_mu1;
        m_mu2;
        m_mu3;
        m_useGraphHeuristics;
    end
    
    methods(Static)
        function r = name()
            r = 'MAD';
        end
    end
    
    methods (Access=public)
        function    result = run( this )
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
            
            this.classPriorNormalization();

            mu1 = this.m_mu1;
            mu2 = this.m_mu2;
            mu3 = this.m_mu3;
            useGraphHeuristics  = this.m_useGraphHeuristics;
            maxIterations       = this.m_num_iterations;
            numVertices         = this.numVertices();
            
            this.logParams();

            Logger.log('Calculating probabilities...');
            if (useGraphHeuristics ~=0)
                p = MAD.calcProbabilities(this.m_W, this.labeledSet());
            else
                p = MAD.constantProbabilities(numVertices);
            end
            result.p = p;
            Logger.log('done');

            % add dummy label. initialy no vertex is
            % associated with the dummy label.
            Logger.log(['size(Y) = ' num2str(size(this.m_priorY))]);
            this.m_priorY = [this.m_priorY zeros(numVertices, 1) ];
            numLabels = this.numLabels();

            % Line (2) of MAD page 10 in reference 
            M = MAD.calcM(this.m_W, p, mu1, mu2, mu3);

            D = zeros( size(this.m_priorY.') );
            r = zeros(numLabels, 1);
            r(end) = 1;

            Y_hat = this.m_priorY.'; % size: numLabels X numVertices
            if this.m_save_all_iterations
                allIterations.Y = zeros( numLabels, numVertices, maxIterations );
            end
%             current_Y = Y_hat;
            
            iteration_diff = 10^1000;
            diff_epsilon = 0.00001;
            
            % note iteration index starts from 2
            for iter_i=2:maxIterations

                Logger.log([ '#Iteration = '      num2str(iter_i)...
                             ' iteration_diff = ' num2str(iteration_diff)]);

                if iteration_diff < diff_epsilon
                    Logger.log(['converged after ' num2str(iter_i-1) ' iterations']);
                    if this.m_save_all_iterations
                        allIterations.Y(:,:, iter_i:end) = []; %#ok<STRNU>
                    end
                    break;
                end

                iteration_diff = 0; %#ok<NASGU>

                % line (4) of MAD page 10 in reference 
                for vertex_i=1:numVertices
                    Dv = MAD.calcDv(this.m_W, p, Y_hat, vertex_i);
                    D( :, vertex_i) = Dv;
                end

                Y_hat_pre = Y_hat; % only used for convergence test.
                % lines (5)-(6)-(7) of MAD page 10 in reference 
                for vertex_i = 1:numVertices
                    p_inject   = p.inject(vertex_i); 
                    p_abandon  = p.abandon(vertex_i); 

                    Yv = this.m_priorY(vertex_i,:).';
%                     Yv = this.priorVector( vertex_i );
                    Dv = D( :, vertex_i );
                    Mv = M( vertex_i );
                    Yv_hat = (1/Mv) * ...
                         (mu1 * p_inject * Yv + ... 
                          mu2 * Dv + ...
                          mu3 * p_abandon * r);
                    Y_hat(:,vertex_i) = Yv_hat;
                end
                iteration_diff = sum((Y_hat_pre(:) - Y_hat(:)).^2);
                if this.m_save_all_iterations
                    allIterations.Y(:,:,iter_i) = Y_hat;
                end
            end
            
            if this.m_save_all_iterations
                for iter_i=1:size(allIterations.Y,3)
                    iterationResult_Y  = allIterations.Y(:,:,iter_i);
                    result.Y(:,:,iter_i) = iterationResult_Y.';
                end 
            else
                result.Y = Y_hat.';
            end

            toc;
        end
    end %     methods (Access=public)
    
    methods (Access=private)
            
        %% logParams
    
        function logParams(this)
            paramsString = ...
                [' useGraphHeuristics = '   num2str(this.m_useGraphHeuristics) ...
                 ' mu1 = '                  num2str(this.m_mu1) ...
                 ' mu2 = '                  num2str(this.m_mu2) ...
                 ' mu3 = '                  num2str(this.m_mu3) ...
                 ' maximum iterations = '   num2str(this.m_num_iterations)...
                 ' num vertices '           num2str(this.numVertices())];                
            Logger.log(['Running ' this.name() '.' paramsString]);            
        end
    end % methods (Acess=private)
    
    methods(Static)
        
        %% calcDv
        
        function Dv = calcDv( W, p, Y_hat, vertex_i )
            %CALCDV Summary of this function goes here
            %   Detailed explanation goes here

            col = W(:, vertex_i);
            % neighbours_indices and neighbours_weights are column
            % vectors
            [neighbours_indices, ~, neighbours_weights] = find(col);
%             neighbours = getNeighbours(W, vertex_i);
            p_continue = p.continue(vertex_i); 

            numLabels = size( Y_hat, 1 );
            Dv = zeros(numLabels,1);

            numNeighbours = length(neighbours_indices);
            for neighbour_i=1:numNeighbours
                neighbour_weight = neighbours_weights(neighbour_i);
                neighbour_id    = neighbours_indices(neighbour_i);
                outgoing = neighbour_weight;
                incoming = W(neighbour_id, vertex_i);
                p_continue_neighbour = p.continue(neighbour_id);
                avg_weight = p_continue * outgoing + ...
                             p_continue_neighbour * incoming;
                Y_neighbour = Y_hat( :, neighbour_id );
                Dv = Dv + avg_weight * Y_neighbour;
            end
        end
        
        %% calcM
        
        function M = calcM( W, p, mu1, mu2, mu3 )
            % Line (2) of MAD page 10 in reference 

            Logger.log('MAD::calcM. Calculating M(v)...');
            
            numVertices = size(W, 1);
            M = zeros( numVertices, 1);

            for vertex_i=1:numVertices
                p_inject   = p.inject(vertex_i); 
                p_continue = p.continue(vertex_i); 
                
                col = W(:, vertex_i);
                % neighbours_indices and neighbours_weights are column
                % vectors
                [neighbours_indices, ~, neighbours_weights] = find(col);
                
                numNeighbours = length(neighbours_indices);
                sumNeighbours = 0;
                for neighbour_i=1:numNeighbours
                    neighbour_weight = neighbours_weights(neighbour_i);
                    neighbour_idx    = neighbours_indices(neighbour_i);
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
            
            Logger.log('MAD::calcM. done.');
        end
        
        %% calcProbabilities
        
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
                col = W(:, vertex_i);
                % neighbours_indices and neighbours_weights are column
                % vectors
                [~, ~, neighbours_weights] = find(col);
                transitions = MAD.calcTransitions( neighbours_weights );
                % entropy calculation using log2 as in vertex.java::GetNeighborhoodEntropy
                entropy = - sum( transitions .* log2(transitions) );
                % natural logarithm and no exp is done in junto_1_0_0
                % in Vertex.java::CalculateRWProbabilities
                % we follow the paper - use the exp (not sure it matters much)
                cv = log(beta) / log( beta + exp( entropy) ) ;
%                 cv = log(beta) / log( beta + entropy ) ;
                isLabeled = ismember( vertex_i, labeledVertices );
                dv = isLabeled * (1-cv) * sqrt( entropy ) ;
                zv = max( cv + dv, 1 );
                p.continue(vertex_i) = cv / zv;
                p.inject  (vertex_i) = dv / zv;
                p.abandon (vertex_i) = 1 - p.continue(vertex_i) - ...
                                       p.inject  (vertex_i);
            end
        end
        
        %% constantProbabilities
        
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
        
        %% calcTransitions
        
        function transitions = calcTransitions(neighboursWeigths )
            %CALCTRANSITIONS Calculate transition probabilitis from neighbours weights

            s = sum( neighboursWeigths );
            transitions = neighboursWeigths / s;
        end
        
    end % methods(Static)
end

