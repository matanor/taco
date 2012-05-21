classdef CSSLMC < CSSLBase
    
methods (Access=public)

%% run
    
function iteration = run( this )

    ticID = tic;

    if (~isempty(this.m_useClassPriorNormalization) && ...
        1 == this.m_useClassPriorNormalization)
        this.classPriorNormalization();
    end

    alpha               = this.m_alpha;
    beta                = this.m_beta;
    zeta                = this.m_zeta;
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

        A = this.transitionMatrix();
        
        for vertex_i=vertexUpdateOrder
            neighbours = getNeighbours( this.m_W, vertex_i);
            isLabeled = this.injectionProbability(vertex_i);
            neighbours_mu = prev_mu( neighbours.indices, : ).';
            neighbours_v  = prev_v ( neighbours.indices, : ).';
            v_i           = prev_v ( vertex_i,:).';
            numNeighbours = length(neighbours.indices);
            sum_K_i_j = zeros(num_labels, 1);
            Q_i       = zeros(num_labels, 1);
            for neighbour_i=1:numNeighbours
                single_neighbour_mu = neighbours_mu(:,neighbour_i);
                single_neighbour_v  = neighbours_v (:,neighbour_i);
                w_i_j = neighbours.weights(neighbour_i);
                K_i_j = w_i_j * ((1./single_neighbour_v) + (1./v_i));
                sum_K_i_j = sum_K_i_j + ...
                    K_i_j .* single_neighbour_mu;
                Q_i = Q_i + K_i_j;
            end
            P_i = isLabeled * ( 1./v_i + 1 / gamma );
            y_i = this.priorVector(vertex_i);
            numerator   = sum_K_i_j + (P_i .* y_i); % .* because P_i is only main diagonal
            denominator = diag(Q_i + P_i + isUsingL2Regularization * 1);
            
            if this.m_isUsingStructured
                structured.previousVertex = this.getPreviousVertexIndex(vertex_i);
                if this.STRUCTURED_NO_VERTEX ~= structured.previousVertex
                    structured.prev_mu = prev_mu( structured.previousVertex, :);
                    structured.prev_v  = prev_v ( structured.previousVertex, :).';
                    G_i = 1./v_i + 1./structured.prev_v;
                    denominator  = denominator + zeta * diag(G_i);
                    numerator    = numerator   + ...
                                   zeta * (diag(G_i) * A * structured.prev_mu.');
                end
                clear structured;

                structured.nextVertex     = this.getNextVertexIndex(vertex_i);
                if this.STRUCTURED_NO_VERTEX ~= structured.nextVertex;
                    structured.next_mu = prev_mu( structured.nextVertex,:);
                    structured.next_v  = prev_v ( structured.nextVertex,:).';
                    G_i_plus1 = 1./v_i + 1./structured.next_v;
                    denominator  = denominator + zeta * diag(G_i_plus1) * A * A;
                    numerator    = numerator   + ...
                                   zeta * (diag(G_i_plus1) * A * structured.next_mu.');
                end
                clear structured;
            end

            if ~isempty(find(numerator,1))
                new_mu = denominator \ numerator;
            else
                new_mu = zeros(1,num_labels);
            end
            iteration.mu(vertex_i, :, iter_i) = new_mu.' ;
            
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
                mu_i = prev_mu(vertex_i,:).';
                for label_i=1:num_labels
                    y_i_r     = this.priorLabelScore( vertex_i, label_i );
                    isLabeled = this.injectionProbability(vertex_i);

                    neighbours = getNeighbours( this.m_W, vertex_i);

                    mu_i_r = prev_mu(vertex_i,label_i);
                    neighbours_mu = prev_mu( neighbours.indices, label_i );
                    R_i = 0.5 * ...
                        ( ...
                            sum ( neighbours.weights .* (mu_i_r  - neighbours_mu).^2 )...
                            + ...
                            isLabeled * (mu_i_r - y_i_r)^2 ...
                        );

                    if this.m_isUsingStructured
                        transitionMatrix_r = this.transitionsToState( label_i ); % Row of A.
                        structured.previousVertex = this.getPreviousVertexIndex(vertex_i);
                        if this.STRUCTURED_NO_VERTEX ~= structured.previousVertex
                            structured.prev_mu = prev_mu( structured.previousVertex, :).';
                            R_i = R_i + 0.5 * zeta * ...
                                ( ...
                                    mu_i_r ...
                                    - ...
                                    transitionMatrix_r * structured.prev_mu ...
                                )^2;
                        end
                        clear structured;

                        structured.nextVertex     = this.getNextVertexIndex(vertex_i);
                        if this.STRUCTURED_NO_VERTEX ~= structured.nextVertex;
                            structured.next_mu_r = prev_mu( structured.nextVertex,label_i);
                            R_i = R_i + 0.5 * zeta *...
                                ( ...
                                    structured.next_mu_r ...
                                    - ...
                                    transitionMatrix_r * mu_i ...
                                )^2;
                        end
                        clear structured;
                        clear transitionMatrix_r;
                    end

                    new_v = (beta + sqrt( beta^2 + 4 * alpha * R_i))...
                            / (2 * alpha);
                    clear R_i;
                    iteration.v(vertex_i, label_i, iter_i) = new_v ;
                end
                    %(beta + sqrt( beta^2 + 4 * alpha * A)) / (2 * alpha);
                    % matan changed 5.12.11 from 4 to 2.
            end
        end

        current_mu  = iteration.mu( :, :, iter_i) ;
        prev_mu     = iteration.mu( :, :, iter_i - 1) ;

        iteration_diff = sum((prev_mu(:) - current_mu(:)).^2);
        if this.m_isCalcObjective
            this.calcObjective( iteration.mu( :, :, iter_i), iteration.v( :, :, iter_i) );
        end
    end

    toc(ticID);
end

%% calcObjective

function calcObjective(this, current_mu, current_v)
    alpha               = this.m_alpha;
    beta                = this.m_beta;
    gamma               = this.m_labeledConfidence;
    numVertices = this.numVertices();
    Logger.log('calcObjective');
    assert(~issparse(this.m_W)); % The calculation is not for sparse matrices.
    objective = 0;
    for vertex_i=1:numVertices
        mu_i = current_mu( vertex_i, :).';
        v_i  = current_v(vertex_i,:).';
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
        if this.m_isUsingStructured
            A = this.transitionMatrix();
            structuredPreviousVertex = this.getPreviousVertexIndex(vertex_i);
            if this.STRUCTURED_NO_VERTEX ~= structuredPreviousVertex
               mu_i_prev = current_mu( structuredPreviousVertex, :).';
               v_i_prev  = current_v ( structuredPreviousVertex, :).';
               G_i = diag( 1./v_i + 1./v_i_prev );
               mu_i_diff = (mu_i - A * mu_i_prev);
               objective = objective + mu_i_diff.' * G_i * mu_i_diff;
            end
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

