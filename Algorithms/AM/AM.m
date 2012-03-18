classdef AM < handle
% Reference: Soft-supervised learning for text classification

properties (Access=public)
    
    m_v;                % Parameter 1. See page 3, bottom left.
    m_mu;               % Parameter 2. See page 3, bottom left.
    m_W;                % The weights of the graph.
    m_alpha;            % parameter 3. See page 5, left column.
    m_num_iterations;
end % properties (Access=public)

methods (Access=public)
        
	function iteration = run( this, labeledY)

        ticID = tic;
        
        v               = this.m_v;
        mu              = this.m_mu;
        alpha           = this.m_alpha;
        num_iterations  = this.m_num_iterations;

        num_vertices = size(labeledY,1);
        num_labels   = size(labeledY,2);
        
        this.displayParams(num_vertices);

        iteration.p = zeros( num_vertices, num_labels, num_iterations );
        iteration.q = zeros( num_vertices, num_labels, num_iterations );
        
        % Initialization requirement is that q^{(0)}(y) > 0 for all y (all
        % labels). Page 5 in reference, top right.
        iteration.q(:,:,1) = 1;
        
        % Change W = W + alpha * I (page 5, top left).
        for vertex_i=1:num_vertices
            this.m_W(vertex_i,vertex_i) = ...
                this.m_W(vertex_i,vertex_i) + alpha;
        end

        iteration_diff = 10^1000;
        diff_epsilon = 0.0001;

        % note iteration index starts from 2
        for iter_i = 2:num_iterations

            if ( mod(iter_i, 2) == 0 )
                disp([ '#Iteration = '      num2str(iter_i)...
                       ' iteration_diff = ' num2str(iteration_diff)]);
            end
            
            if iteration_diff < diff_epsilon
                disp([  'converged after '   num2str(iter_i-1) ' iterations'...
                        ' iteration_diff = ' num2str(iteration_diff)]);
                iteration.p(:,:, iter_i:end) = [];
                iteration.q(:,:, iter_i:end) = [];
                break;
            end

            prev_q = iteration.q ( :, :, iter_i - 1) ;

            % Page 5 in reference (see top of this file), top right, see equations

            % calculate p_i^{(n)} for all i (i.e. all vertices)
            % from q_j^{(n-1)}
            for vertex_i=1:num_vertices
                neighbours = getNeighbours( this.m_W, vertex_i);

                % calculate \beta_i^{(n-1)}(y) for all y (all labels)
                beta = zeros(num_labels, 1);
                for label_i = 1:num_labels
                    q_neighbours = prev_q(neighbours.indices, label_i);
                    beta(label_i) = -v + mu * sum( neighbours.weights .* (log( q_neighbours ) - 1) );
                end
                
                gamma = v + mu * sum( neighbours.weights );
                
                % from beta (vector) and gamma (scalar) calculate p_i^{(n)}
                p_i = exp( beta / gamma );
                p_i = p_i / sum(p_i); % normalize to probability.
                
                % save the calculation
                iteration.p(vertex_i,:,iter_i) = p_i.';
            end

            current_p = iteration.p( :, :, iter_i) ;

            % calculate q_j^{(n)} for all i (i.e. all vertices)
            % from p_i^{(n)}
            for vertex_i=1:num_vertices
                neighbours = getNeighbours( this.m_W, vertex_i);
                
                y_i = labeledY( vertex_i, : );
                isLabeled = (sum(y_i) ~=0);
                
                q_i = zeros(num_labels, 1);

                for label_i = 1:num_labels
                    p_neighbours = current_p(neighbours.indices, label_i);
                    q_i(label_i) = isLabeled * y_i(label_i) + ...
                                   mu * sum( neighbours.weights .* p_neighbours);
                end
                
                q_i_denominator = isLabeled + mu * sum( neighbours.weights );
                q_i = q_i / q_i_denominator;
                
                % save the calculation
                iteration.q(vertex_i,:,iter_i) = q_i.';
            end

            prev_p = iteration.p ( :, :, iter_i - 1) ;
            iteration_diff = sum((prev_p(:) - current_p(:)).^2);
        end

        toc(ticID);
    end
    
    %% diaplayParams
    
	function displayParams(this, numVertices)
        paramsString = ...
                [' mu = '                num2str(this.m_mu) ...
                 ' v = '                 num2str(this.m_v) ...
                 ' alpha = '             num2str(this.m_alpha) ...
                 ' maxIterations = '     num2str(this.m_num_iterations)...
                 ' num vertices = '      num2str(numVertices) ];                
        disp(['Running ' this.name() '.' paramsString]);
    end
        
end % methods (Access=public)
    
methods(Static)
   function r = name()
       r = 'AM';
   end
end % methods(Static)
    
end

