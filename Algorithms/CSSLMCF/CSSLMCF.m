classdef CSSLMCF < CSSLBase
% Confidence Semi-Supervised Learning Multi-Class Full Covariance
    
    methods (Access=public)
        
	function result = run( this )

        ticID = tic;
        
        this.classPriorNormalization();
        
        alpha                   = this.m_alpha;
        beta                    = this.m_beta;
        num_iterations          = this.m_num_iterations;
        gamma                   = this.m_labeledConfidence;
        isUsingL2Regularization = this.m_isUsingL2Regularization;
        isUsingSecondOrder      = this.m_isUsingSecondOrder;
        
        num_vertices = this.numVertices();
        num_labels   = this.numLabels();
        this.displayParams(CSSLMCF.name());
        
        prev_mu     =  zeros( num_labels, num_vertices );
        current_mu  =  zeros( num_labels, num_vertices );

        if 0 == isUsingSecondOrder
            initFactor_v = (beta / alpha);
        else
            initFactor_v = 1;
        end
        
        prev_sigma  =  ones ( num_labels, num_labels, num_vertices ) * initFactor_v;
        curr_sigma  =  ones ( num_labels, num_labels, num_vertices ) * initFactor_v;
        whos prev_sigma;
        whos curr_sigma;

        if this.m_save_all_iterations
            allIterations.mu     = zeros( num_labels,               num_vertices, num_iterations );
            allIterations.sigma  = ones ( num_labels, num_labels,   num_vertices, num_iterations ) * initFactor_v;
        end
        
        for vertex_i=1:num_vertices
            prev_sigma(:,:,vertex_i) = eye( num_labels );
        end

        inv_gamma = diag( zeros(1,num_labels) + 1 / gamma );
        
        this.prepareGraph();
        
        iteration_diff  = Inf;
        diff_epsilon    = this.m_diffEpsilon; 
        
        % note iteration index starts from 2
        for iter_i = 2:num_iterations

            Logger.log([  '#Iteration = ' num2str(iter_i)...
                    ' iteration_diff = ' num2str(iteration_diff)]);
            
            if iteration_diff < diff_epsilon
                Logger.log(['converged after ' num2str(iter_i-1) ' iterations.'...
                      ' iteration_diff = ' num2str(iteration_diff)]);
                allIterations.mu   (:,:,   iter_i:end) = [];
                allIterations.sigma(:,:,:, iter_i:end) = [];
                break;
            end
            
            inv_prev_sigma = zeros( num_labels, num_labels, num_vertices );
            for vertex_i=1:num_vertices
                sigma_i                        = prev_sigma(:,:,vertex_i );
                inv_prev_sigma(:, :, vertex_i) = inv( sigma_i );
            end
            
            for vertex_i=1:num_vertices
                if ( mod(vertex_i, 100000) == 0 )
                    Logger.log([ 'vertex_i = ' num2str(vertex_i)]);
                end
                inv_sigma_i = inv_prev_sigma(:,:,vertex_i);
                
                isLabeled = this.m_isLabeledVector(vertex_i);
                
                P_i = isLabeled * (inv_sigma_i + inv_gamma);
                    
                col = this.m_W(:, vertex_i);
                [neighbours_indices, ~, neighbours_weights] = find(col);
                
                num_neighbours  = length( neighbours_weights);
                Q_i             = zeros( num_labels, num_labels );               
                sum_K_i_j       = zeros( num_labels, 1 );
                
                for neighbour_i=1:num_neighbours
                    neighbour_id     = neighbours_indices(neighbour_i); % integer
                    weight           = neighbours_weights(neighbour_i); % scalar
                    neighbour_mu     = prev_mu( :, neighbour_id );      % column vector
                    inv_neighbour_sigma = inv_prev_sigma(:,:,neighbour_id);
                    covariance = ...
                        weight * (inv_sigma_i + inv_neighbour_sigma);
                    Q_i = Q_i + covariance;
                    K_i_j = covariance * neighbour_mu;
                    sum_K_i_j = sum_K_i_j + K_i_j;
                end
                
                Q_i = Q_i + isUsingL2Regularization * eye(size(Q_i));
                
                % y_i size is (num_labels X 1)
                y_i    = this.m_priorY(vertex_i,:).';
                new_mu = ( Q_i + P_i ) \ ( sum_K_i_j + P_i * y_i );

                current_mu( :, vertex_i) = new_mu.';
            end

            if isUsingSecondOrder
                for vertex_i=1:num_vertices
                    if ( mod(vertex_i, 100000) == 0 )
                        Logger.log([ 'vertex_i = ' num2str(vertex_i)]);
                    end

                    isLabeled = this.m_isLabeledVector(vertex_i);

                    col = this.m_W(:, vertex_i);
                    [neighbours_indices, ~, neighbours_weights] = find(col);

                    num_neighbours  = length( neighbours_weights);
                    mu_i            = prev_mu( :, vertex_i ); % column vector

                    R_i = zeros( num_labels, num_labels );
                    for neighbour_i=1:num_neighbours
                        neighbour_id     = neighbours_indices(neighbour_i);
                        weight           = neighbours_weights(neighbour_i);
                        neighbour_mu     = prev_mu( :, neighbour_id );
                        mu_diff = mu_i - neighbour_mu;
                        R_i = R_i + weight * (mu_diff * mu_diff.');
                    end

                    y_i       = this.m_priorY(vertex_i,:).';
                    mu_diff_y = mu_i - y_i;

                    R_i = 0.5 * (R_i + isLabeled * (mu_diff_y * mu_diff_y.'));
                    new_sigma_i = CSSLMCF.solveQuadratic( - (beta/alpha), - (1/alpha) * R_i);
                    curr_sigma( :,:, vertex_i) = new_sigma_i;
                end
            end
            
            iteration_diff = sum((prev_mu(:) - current_mu(:)).^2);
            
            if this.m_save_all_iterations
                allIterations.mu     ( :, :,    iter_i)    = current_mu;
                allIterations.sigma  ( :, :, :, iter_i)    = current_v;
            end
        
            % Advance iteration
            prev_mu     = current_mu;
            prev_sigma  = curr_sigma;
        end % loop over all iterations

        toc(ticID);
        
        if this.m_save_all_iterations
            for iter_i=1:size(allIterations.mu,3)
                iterationResult_mu       = allIterations.mu(:,:,iter_i);
                result.mu      (:,:,  iter_i) = iterationResult_mu.';
            end
            result.sigma    = allIterations.sigma;
        else
            result.sigma           = curr_sigma;
            result.mu              = current_mu.';
        end
    
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

