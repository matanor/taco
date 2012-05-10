classdef AM < GraphTrunsductionBase
% Reference: Soft-supervised learning for text classification

properties (Access=public)
    m_v;                % Parameter 1. See page 3, bottom left.
    m_mu;               % Parameter 2. See page 3, bottom left.
    m_alpha;            % parameter 3. See page 5, left column.
end % properties (Access=public)

methods (Access=public)
       
    function this = AM()
        this.m_useClassPriorNormalization = 0;
    end
    
	function iteration = run( this )

        ticID = tic;
        
        v               = this.m_v;
        mu              = this.m_mu;
        alpha           = this.m_alpha;
        num_iterations  = this.m_num_iterations;

        num_vertices = this.numVertices();
        num_labels   = this.numLabels();
        
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
                Logger.log([ '#Iteration = '      num2str(iter_i)...
                       ' iteration_diff = ' num2str(iteration_diff)]);
            end
            
            if iteration_diff < diff_epsilon
                Logger.log([  'converged after '   num2str(iter_i-1) ' iterations'...
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
                
                isLabeled = this.isLabeled(vertex_i );
                
                q_i = zeros(num_labels, 1);

                for label_i = 1:num_labels
                    y_i_l = this.priorLabelScore( vertex_i, label_i );
                    p_neighbours = current_p(neighbours.indices, label_i);
                    q_i(label_i) = isLabeled * y_i_l + ...
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
    
    %% checkIfInitModeMathcesAlgorithm
    
    function R = checkIfInitModeMathcesAlgorithm(~, ~)
        % allow derived classes (specific algorithme) to change
        % the labels init mode if they don't like it.
        % e.g. for AM the labels prior must be a distribution, so we
        % cannot initialize any priorY entries to -1.
        Logger.log('AM: forcing prior Y to be a probability distribution');
        R = ParamsManager.LABELED_INIT_ZERO_ONE;
    end

    %% displayParams
    
	function displayParams(this, numVertices)
        paramsString = ...
                [' mu = '                num2str(this.m_mu) ...
                 ' v = '                 num2str(this.m_v) ...
                 ' alpha = '             num2str(this.m_alpha) ...
                 ' maxIterations = '     num2str(this.m_num_iterations)...
                 ' num vertices = '      num2str(numVertices) ];                
        Logger.log(['Running ' this.name() '.' paramsString]);
    end
        
end % methods (Access=public)
    
methods(Static)
   function r = name()
       r = 'AM';
   end
end % methods(Static)
    
end

