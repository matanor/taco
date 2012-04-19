classdef CSSLMCF < CSSLBase
% Confidence Semi-Supervised Learning Multi-Class Full Covariance
    
    methods (Access=public)
        
	function result = run( this )

        ticID = tic;
        
        this.classPriorNormalization();
        
        alpha               = this.m_alpha;
        beta                = this.m_beta;
        num_iterations      = this.m_num_iterations;
        gamma               = this.m_labeledConfidence;
        isUsingL2Regularization = this.m_isUsingL2Regularization;
        isUsingSecondOrder  = this.m_isUsingSecondOrder;
        
        num_vertices = this.numVertices();
        num_labels   = this.numLabels();
        this.displayParams(CSSLMCF.name());

        result.mu     = zeros( num_vertices, num_labels, num_iterations );
        result.sigma  = ones ( num_labels, num_labels, num_vertices, num_iterations );
        for vertex_i=1:num_vertices
            for iteration_i=1:num_iterations
                result.sigma(:,:,vertex_i,iteration_i) = eye( num_labels );
            end
        end
        if 0 == isUsingSecondOrder
            result.sigma = result.sigma * (beta/alpha);
        end

        inv_gamma = diag( zeros(1,num_labels) + 1 / gamma );
        
        this.prepareGraph();
        
        iteration_diff  = 10^1000;
        diff_epsilon    = 0.0001;
        
        % note iteration index starts from 2
        for iter_i = 2:num_iterations

            Logger.log([  '#Iteration = ' num2str(iter_i)...
                    ' iteration_diff = ' num2str(iteration_diff)]);
            
            if iteration_diff < diff_epsilon
                Logger.log(['converged after ' num2str(iter_i-1) ' iterations.'...
                      ' iteration_diff = ' num2str(iteration_diff)]);
                result.mu(:,:, iter_i:end) = [];
                result.sigma(:,:,:, iter_i:end) = [];
                break;
            end
            
            prev_mu     = result.mu    ( :, :, iter_i - 1) ;
            prev_sigma  = result.sigma ( :, :, :, iter_i - 1) ;

            inv_prev_sigma = zeros( num_labels, num_labels, num_vertices );
            for vertex_i=1:num_vertices
                sigma_i = prev_sigma(:,:,vertex_i );
                inv_prev_sigma(:, :, vertex_i) = inv( sigma_i );
            end
            
            for vertex_i=1:num_vertices
                inv_sigma_i = inv_prev_sigma(:,:,vertex_i);
                
                isLabeled = this.injectionProbability(vertex_i);
                
                P_i = isLabeled * (inv_sigma_i + inv_gamma);
                    
                neighbours      = getNeighbours( this.m_W, vertex_i);
                num_neighbours  = length( neighbours.weights);
                Q_i             = zeros( num_labels, num_labels );               
                sum_K_i_j       = zeros( num_labels, 1 );
                
                for neighbour_i=1:num_neighbours
                    neighbour_id     = neighbours.indices(neighbour_i);
                    neighbour_weight = neighbours.weights(neighbour_i);
                    neighbour_mu     = prev_mu( neighbour_id, : ).';
                    inv_neighbour_sigma = inv_prev_sigma(:,:,neighbour_id);
                    covariance = ...
                        neighbour_weight * (inv_sigma_i + inv_neighbour_sigma);
                    Q_i = Q_i + covariance;
                    K_i_j = covariance * neighbour_mu;
                    sum_K_i_j = sum_K_i_j + K_i_j;
                end
                
                Q_i = Q_i + isUsingL2Regularization * eye(size(Q_i));
                
                y_i       = this.priorVector( vertex_i );
                new_mu = ( Q_i + P_i ) \ ( sum_K_i_j + P_i * y_i );

                result.mu( vertex_i, :, iter_i) = new_mu.';
            end

            if isUsingSecondOrder
                for vertex_i=1:num_vertices
                    isLabeled = this.injectionProbability(vertex_i);

                    neighbours      = getNeighbours( this.m_W, vertex_i);
                    num_neighbours  = length( neighbours.weights);
                    mu_i            = prev_mu( vertex_i, : ).';

                    R_i = zeros( num_labels, num_labels );
                    for neighbour_i=1:num_neighbours
                        neighbour_id     = neighbours.indices(neighbour_i);
                        neighbour_weight = neighbours.weights(neighbour_i);
                        neighbour_mu     = prev_mu( neighbour_id, : ).';
                        mu_diff = mu_i - neighbour_mu;
                        R_i = R_i + neighbour_weight * (mu_diff * mu_diff.');
                    end

                    y_i       = this.priorVector( vertex_i );
                    mu_diff_y = mu_i - y_i;

                    R_i = 0.5 * (R_i + isLabeled * (mu_diff_y * mu_diff_y.'));
                    new_sigma_i = CSSLMCF.solveQuadratic( - (beta/alpha), - (1/alpha) * R_i);
                    result.sigma( :,:, vertex_i, iter_i) = new_sigma_i;
                end
            end
            
            current_mu     = result.mu( :, :, iter_i) ;
            iteration_diff = sum((prev_mu(:) - current_mu(:)).^2);
        end

        toc(ticID);
    
        end
    end % methods (Access=public)
    
    methods(Static)
       function X = solveQuadratic(s, C)
           % solve: I * X^2 + s * I * X + C = 0
           B = s * eye( size(C) );
           
            det = B*B-4*C;
            [Vdet, Ddet] = eig(det);
            sqrt_det = Vdet * (Ddet.^0.5) * Vdet.';
            X = - 0.5 * B + 0.5 * (sqrt_det);
       end
       function r = name()
           r = 'CSSLMCF';
       end
    end % methods(Static)
    
end

