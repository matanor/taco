classdef CSSLMC < CSSLBase

methods (Access=public)
        
	function iteration = run( this, labeledY)

        ticID = tic;
        
        alpha               = this.m_alpha;
        beta                = this.m_beta;
        num_iterations      = this.m_num_iterations;
        gamma               = this.m_labeledConfidence;

        this.displayParams('CSSLMC');
        
        num_vertices = size(labeledY,1);
        num_labels   = size(labeledY,2);

        iteration.mu = zeros( num_vertices, num_labels, num_iterations );
        iteration.v  = ones ( num_vertices, num_labels, num_iterations );
        
        this.prepareGraph(labeledY);
        
        iteration_diff = 10^1000;
        diff_epsilon = 0.0001;

        % note iteration index starts from 2
        for iter_i = 2:num_iterations

            if ( mod(iter_i, 2) == 0 )
                disp([ '#Iteration = ' num2str(iter_i)...
                       ' iteration_diff = ' num2str(iteration_diff)]);
            end
            
            if iteration_diff < diff_epsilon
                disp([  'converged after '   num2str(iter_i-1) ' iterations'...
                        ' iteration_diff = ' num2str(iteration_diff)]);
                iteration.mu(:,:, iter_i:end) = [];
                iteration.v(:,:, iter_i:end) = [];
                break;
            end
                
            prev_mu = iteration.mu( :, :, iter_i - 1) ;
            prev_v =  iteration.v ( :, :, iter_i - 1) ;

            for vertex_i=1:num_vertices

                for label_i = 1:num_labels

                    y_i = labeledY( vertex_i, label_i );
                    isLabeled = this.injectionProbability(vertex_i,y_i);
                    
                    neighbours = getNeighbours( this.m_W, vertex_i);

                    ni = sum( neighbours.weights ) + isLabeled;
                    neighbours_mu = prev_mu( neighbours.indices, label_i );
                    neighbours_v  = prev_v ( neighbours.indices, label_i );
                    B = sum( neighbours.weights .* neighbours_mu ) ...
                        + isLabeled * y_i;
                    C = sum( neighbours.weights .* neighbours_mu ./ neighbours_v ) ...
                        + isLabeled * (y_i / gamma) ;
                    D = sum( neighbours.weights ./ neighbours_v ) ...
                        + isLabeled / gamma + 1;

                    new_mu =    (B + prev_v(vertex_i,label_i) * C) / ...
                                (ni + prev_v(vertex_i,label_i) * D);
                    iteration.mu(vertex_i, label_i, iter_i) = new_mu ;
                end
            end

            for vertex_i=1:num_vertices
                
                for label_i=1:num_labels
                    y_i = labeledY( vertex_i, label_i );
                    isLabeled = this.injectionProbability(vertex_i,y_i);

                    neighbours = getNeighbours( this.m_W, vertex_i);

                    mu_i = prev_mu(vertex_i,label_i);
                    neighbours_mu = prev_mu( neighbours.indices, label_i );
                    A = sum ( neighbours.weights .* ...
                        (mu_i  - neighbours_mu).^2 )...
                        + isLabeled * 0.5 *  (mu_i -y_i)^2;

                    new_v = (beta + sqrt( beta^2 + 4 * alpha * A))...
                            / (2 * alpha);
                    iteration.v(vertex_i, label_i, iter_i) = new_v ;
                end

                    %(beta + sqrt( beta^2 + 4 * alpha * A)) / (2 * alpha);
                    % matan changed 5.12.11 from 4 to 2.
            end
            
            current_mu = iteration.mu( :, :, iter_i) ;
            
            iteration_diff = sum((prev_mu(:) - current_mu(:)).^2);
        end

        toc(ticID);
%         disp('size(iteration.v)=');
%         disp(size(iteration.v));
    
    end
        
end % methods (Access=public)
    
methods(Static)
   function r = name()
       r = 'CSSLMC';
   end
end % methods(Static)
    
end

