classdef CSSLMC < CSSLBase

methods (Access=public)
        
	function iteration = run( this )

        ticID = tic;
        
        if (~isempty(this.m_useClassPriorNormalization) && ...
            1 == this.m_useClassPriorNormalization)
            this.classPriorNormalization();
        end
        
        alpha               = this.m_alpha;
        beta                = this.m_beta;
        num_iterations      = this.m_num_iterations;
        gamma               = this.m_labeledConfidence;
        isUsingL2Regularization = this.m_isUsingL2Regularization;
        isUsingSecondOrder  = this.m_isUsingSecondOrder;

        this.displayParams(CSSLMC.name());
        
        num_vertices = this.numVertices();
        num_labels   = this.numLabels();

        iteration.mu = zeros( num_vertices, num_labels, num_iterations );
        iteration.v  = ones ( num_vertices, num_labels, num_iterations );
        if 0 == isUsingSecondOrder
            iteration.v = (beta / alpha ) * iteration.v;
        end
        
        this.prepareGraph();
        
        iteration_diff = 10^1000;
        diff_epsilon = 0.0001;
        
        if this.DESCEND_MODE_AM == this.m_descendMode
            vertexUpdateOrder = randperm(num_vertices);
        else
            vertexUpdateOrder = 1:num_vertices;
        end

        % note iteration index starts from 2
        for iter_i = 2:num_iterations

            if ( mod(iter_i, 2) == 0 )
                Logger.log([ '#Iteration = ' num2str(iter_i)...
                       ' iteration_diff = ' num2str(iteration_diff)]);
            end
            
            if iteration_diff < diff_epsilon
                Logger.log([  'converged after '   num2str(iter_i-1) ' iterations'...
                        ' iteration_diff = ' num2str(iteration_diff)]);
                iteration.mu(:,:, iter_i:end) = [];
                iteration.v(:,:, iter_i:end) = [];
                break;
            end
                
            prev_mu = iteration.mu( :, :, iter_i - 1) ;
            prev_v =  iteration.v ( :, :, iter_i - 1) ;

            for vertex_i=vertexUpdateOrder

                for label_i = 1:num_labels

                    y_i_l = this.priorLabelScore( vertex_i, label_i );
                    isLabeled = this.injectionProbability(vertex_i);
                    
                    neighbours = getNeighbours( this.m_W, vertex_i);

                    ni = sum( neighbours.weights ) + isLabeled;
                    neighbours_mu = prev_mu( neighbours.indices, label_i );
                    neighbours_v  = prev_v ( neighbours.indices, label_i );
                    B = sum( neighbours.weights .* neighbours_mu ) ...
                        + isLabeled * y_i_l;
                    C = sum( neighbours.weights .* neighbours_mu ./ neighbours_v ) ...
                        + isLabeled * (y_i_l / gamma) ;
                    D = sum( neighbours.weights ./ neighbours_v ) ...
                        + isLabeled / gamma + isUsingL2Regularization * 1;

                    new_mu =    (B + prev_v(vertex_i,label_i) * C) / ...
                                (ni + prev_v(vertex_i,label_i) * D);
                    iteration.mu(vertex_i, label_i, iter_i) = new_mu ;
                end
                if this.DESCEND_MODE_AM == this.m_descendMode
                    % for true AM
                    prev_mu(vertex_i,:) = iteration.mu(vertex_i, :, iter_i);
                end
            end
            
            if this.m_descendMode == this.DESCEND_MODE_2 
                prev_mu = iteration.mu( :, :, iter_i) ;
            end

            if isUsingSecondOrder
                for vertex_i=1:num_vertices
                    for label_i=1:num_labels
                        y_i_l     = this.priorLabelScore( vertex_i, label_i );
                        isLabeled = this.injectionProbability(vertex_i);

                        neighbours = getNeighbours( this.m_W, vertex_i);

                        mu_i = prev_mu(vertex_i,label_i);
                        neighbours_mu = prev_mu( neighbours.indices, label_i );
                        A = 0.5 * (sum ( neighbours.weights .* ...
                            (mu_i  - neighbours_mu).^2 )...
                            + isLabeled * (mu_i -y_i_l)^2 );

                        new_v = (beta + sqrt( beta^2 + 4 * alpha * A))...
                                / (2 * alpha);
                        iteration.v(vertex_i, label_i, iter_i) = new_v ;
                    end
                        %(beta + sqrt( beta^2 + 4 * alpha * A)) / (2 * alpha);
                        % matan changed 5.12.11 from 4 to 2.
                end
            end
            
            current_mu  = iteration.mu( :, :, iter_i) ;
            prev_mu     = iteration.mu( :, :, iter_i - 1) ;
            
            iteration_diff = sum((prev_mu(:) - current_mu(:)).^2);
            this.calcObjective( iteration.mu( :, :, iter_i), iteration.v( :, :, iter_i) );
        end

        toc(ticID);
    end
    
    function calcObjective(this, current_mu, current_v)
        alpha               = this.m_alpha;
        beta                = this.m_beta;
        gamma               = this.m_labeledConfidence;
        numVertices = this.numVertices();
        Logger.log('calcObjective');
        objective = 0;
        for vertex_i=1:numVertices
            mu_i = current_mu( vertex_i, :).';
            v_i = current_v(vertex_i,:).';
            %if mod(vertex_i, 100) == 0
            %    disp(vertex_i);
            %end
            for vertex_j=1:numVertices
                w_i_j = this.m_W(vertex_i, vertex_j);
                mu_j = current_mu( vertex_j, :).';
                v_j = current_v(vertex_i,:).';
                objective = objective + ...
                    0.25 * w_i_j * sum((1./v_i + 1 ./ v_j) .* ((mu_i - mu_j).^2));
            end
            isLabeled_i = this.injectionProbability(vertex_i);
            if isLabeled_i
                y_i = this.priorLabelScore( vertex_i, : ).';
                objective = objective + ...
                    0.5 * sum((1./v_i + 1/gamma) .* ((mu_i - y_i).^2));
            end
        end
        objective = objective + alpha * sum(sum(current_v));
        objective = objective - beta  * sum(sum(log(current_v)));
        Logger.log(['Objective = ' num2str(objective)]);
    end
        
end % methods (Access=public)
    
methods(Static)
   function r = name()
       r = 'CSSLMC';
   end
end % methods(Static)
    
end

