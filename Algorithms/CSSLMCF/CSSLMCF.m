classdef CSSLMCF < CSSLBase
% Confidence Semi-Supervised Learning Multi-Class Full Covariance

%     properties (SetAccess=public, GetAccess=protected)
%         m_W;
%         m_num_iterations;
%         m_alpha;
%         m_beta;
%         m_labeledConfidence;
%     end
    
    methods (Access=public)
        
	function result = run( this, labeledY)

        tic;
        
        alpha               = this.m_alpha;
        beta                = this.m_beta;
        num_iterations      = this.m_num_iterations;
        gamma               = this.m_labeledConfidence;
        
        num_vertices = size(labeledY,1);
        num_labels   = size(labeledY,2);
        disp(['confidenceSSL (multiclass full). num vertices: ' num2str(num_vertices)]);

        result.mu     = zeros( num_vertices, num_labels, num_iterations );
        result.sigma  = ones ( num_vertices, num_labels, num_labels, num_iterations );
        first_iteration = 1;
        for vertex_i=1:num_vertices
            result.sigma(vertex_i,:,:,first_iteration) = eye( num_labels );
        end

        inv_gamma = diag( zeros(1,num_labels) + 1 / gamma );
        
        % note iteration index starts from 2
        for iter_i = 2:num_iterations

            if ( mod(iter_i, 10) == 0 )
                disp(['#Iteration = ' num2str(iter_i)]);
            end
            prev_mu     = result.mu    ( :, :, iter_i - 1) ;
            prev_sigma  = result.sigma ( :, :, :, iter_i - 1) ;

            inv_prev_sigma = zeros( num_vertices, num_labels, num_labels );
            for vertex_i=1:num_vertices
                sigma_i(:,:) = prev_sigma(vertex_i,:,: );
                inv_prev_sigma(vertex_i, :, :) = ...
                    inv( sigma_i );
            end
            
            for vertex_i=1:num_vertices
                inv_sigma_i(:,:) = inv_prev_sigma(vertex_i,:,:);
                
                y_i       = labeledY( vertex_i, : ).';
                isLabeled = (sum(y_i) ~=0);
                
                P_i = isLabeled * (inv_sigma_i + inv_gamma);
                    
                neighbours      = getNeighbours( this.m_W, vertex_i);
                num_neighbours  = length( neighbours.weights);
                Q_i             = zeros( num_labels, num_labels );               
                sum_K_i_j       = zeros( num_labels, 1 );
                
                for neighbour_i=1:num_neighbours
                    neighbour_id     = neighbours.indices(neighbour_i);
                    neighbour_weight = neighbours.weights(neighbour_i);
                    neighbour_mu     = prev_mu( neighbour_id, : ).';
                    inv_neighbour_sigma(:,:) = inv_prev_sigma(neighbour_id,:,:);
                    covariance = ...
                        neighbour_weight * (inv_sigma_i + inv_neighbour_sigma);
                    Q_i = Q_i + covariance;
                    K_i_j = covariance * neighbour_mu;
                    sum_K_i_j = sum_K_i_j + K_i_j;
                end
                
                new_mu = ( Q_i + P_i ) \ ( sum_K_i_j + P_i * y_i );

                result.mu( vertex_i, :, iter_i) = new_mu.';
            end

            for vertex_i=1:num_vertices
                
                y_i       = labeledY( vertex_i, : ).';
                isLabeled = (sum(y_i) ~=0);
                
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
                mu_diff_y = mu_i - y_i;
                R_i = R_i + 0.5 * isLabeled * (mu_diff_y * mu_diff_y.');
                new_sigma_i = CSSLMCF.solveQuadratic( - (beta/alpha), - (1/alpha) * R_i);
                result.sigma( vertex_i, :,:, iter_i) = new_sigma_i;
            end
        end

        toc;
    
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

