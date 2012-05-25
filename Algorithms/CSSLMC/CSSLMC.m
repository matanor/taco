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

    prev_mu     =  zeros( num_labels, num_vertices );
    current_mu  =  zeros( num_labels, num_vertices );
    prev_v      =  ones ( num_labels, num_vertices );
    if 0 == isUsingSecondOrder
        prev_v = (beta / alpha ) * prev_v;
    end

    this.prepareGraph();
    
    iteration_diff = 10^1000;
    diff_epsilon = 0.0001;

    %if this.DESCEND_MODE_AM == this.m_descendMode
     %   vertexUpdateOrder = randperm(num_vertices);
    %else
        vertexUpdateOrder = 1:num_vertices;
    %end

    % note iteration index starts from 2
    for iter_i = 2:num_iterations
        Logger.log([ '#Iteration = ' num2str(iter_i)...
                     ' iteration_diff = ' num2str(iteration_diff)]);
        if iteration_diff < diff_epsilon
            Logger.log([  'converged after '   num2str(iter_i-1) ' iterations'...
                          ' iteration_diff = ' num2str(iteration_diff)]);
            break;
        end
        iteration_diff = 0;
        
        Logger.log('Updating first order...');

        A = this.transitionMatrix();
        zeta_times_A_tran = zeta * A.';
        
        for vertex_i=vertexUpdateOrder
            if ( mod(vertex_i, 100000) == 0 )
                Logger.log([ 'vertex_i = ' num2str(vertex_i)]);
            end

            col = this.m_W(:, vertex_i);
            [neighbours_indices, ~, neighbours_weights] = find(col);
    
            isLabeled = this.m_isLabeledVector(vertex_i);
            neighbours_mu = prev_mu( :, neighbours_indices );
            neighbours_v  = prev_v ( :, neighbours_indices );
            v_i           = prev_v ( :, vertex_i);
            numNeighbours = length(neighbours_indices);
            sum_K_i_j = zeros(num_labels, 1);
            Q_i       = zeros(num_labels, 1);
            for neighbour_i=1:numNeighbours
                single_neighbour_mu = neighbours_mu(:,neighbour_i);
                single_neighbour_v  = neighbours_v (:,neighbour_i);
                w_i_j = neighbours_weights(neighbour_i);
                K_i_j = w_i_j * ((1./single_neighbour_v) + (1./v_i));
                sum_K_i_j = sum_K_i_j + ...
                    K_i_j .* single_neighbour_mu;
                Q_i = Q_i + K_i_j;
            end
            P_i = isLabeled * ( 1./v_i + 1 / gamma );
            y_i = this.m_priorY(vertex_i,:).';
            numerator   = sum_K_i_j + (P_i .* y_i); % .* because P_i is only main diagonal
            denominator = diag(Q_i + P_i + isUsingL2Regularization * 1);
            
            if this.m_isUsingStructured
                structuredPreviousVertex = this.m_structuredInfo.previous(vertex_i);
                if this.STRUCTURED_NO_VERTEX ~= structuredPreviousVertex
                    structuredPrev_mu = prev_mu( :, structuredPreviousVertex );
                    structuredPrev_v  = prev_v ( :, structuredPreviousVertex);
                    G_i = 1./v_i + 1./structuredPrev_v;
                    denominator  = denominator + zeta * diag(G_i);
                    numerator    = numerator   + ...
                                   zeta * (G_i .* (A * structuredPrev_mu));
                end

                structuredNextVertex     = this.m_structuredInfo.next(vertex_i);
                if this.STRUCTURED_NO_VERTEX ~= structuredNextVertex;
                    structuredNext_mu = prev_mu( :, structuredNextVertex);
                    structuredNext_v  = prev_v ( :, structuredNextVertex);
                    G_i_plus1 = 1./v_i + 1./structuredNext_v;
                    % This is what repmat does - only without all the time
                    % wasting if's
                    G_i_plus1_repmat = G_i_plus1(:, ones(num_labels, 1));
                    denominator  = denominator + ...
                                   zeta_times_A_tran * ( G_i_plus1_repmat .* A );
                    numerator    = numerator   + ...
                                   zeta_times_A_tran * (G_i_plus1 .* structuredNext_mu);
                end
            end

            if ~isempty(find(numerator,1))
                new_mu = denominator \ numerator;
            else
                new_mu = zeros(1,num_labels);
            end
            current_mu(:, vertex_i) = new_mu ;
            
            if this.DESCEND_MODE_AM == this.m_descendMode
                % for true AM
                iteration_diff = iteration_diff + ...
                                 sum(current_mu(:, vertex_i) - prev_mu(:,vertex_i)).^2;
                prev_mu(:,vertex_i) = current_mu( :, vertex_i);
            end
        end

        if this.m_descendMode == this.DESCEND_MODE_2 
            iteration_diff = sum(sum((prev_mu - current_mu).^2));
            prev_mu = current_mu ;
        end
        
        Logger.log('Updating second order...');

        if isUsingSecondOrder
            for vertex_i=1:num_vertices
                if ( mod(vertex_i, 100000) == 0 )
                    Logger.log([ 'vertex_i = ' num2str(vertex_i)]);
                end
                isLabeled = this.m_isLabeledVector(vertex_i);
                col = this.m_W(:, vertex_i);
                [neighbours_indices, ~, neighbours_weights] = find(col);
                if this.m_isUsingStructured
                    structured.previousVertex = this.m_structuredInfo.previous(vertex_i);
                    structured.nextVertex     = this.m_structuredInfo.next(vertex_i);
                end
                
                y_i  = this.m_priorY(vertex_i,:).';
                mu_i = prev_mu(:,vertex_i);
                numNeighbours = length( neighbours_indices );
                neighbours_mu = prev_mu( :, neighbours_indices );
                neighboursSquaredDiff = zeros(num_labels, numNeighbours);
                for neighbour_i=1:numNeighbours
                    neighboursSquaredDiff(:,neighbour_i) = ...
                        neighbours_weights(neighbour_i) * ...
                            ((mu_i - neighbours_mu(:,neighbour_i)).^2);
                end

                R_i = 0.5 * sum(neighboursSquaredDiff,2);
                if isLabeled
                   R_i = R_i +  0.5 * ((mu_i - y_i).^2);
                end
                
                if this.m_isUsingStructured        
                    if this.STRUCTURED_NO_VERTEX ~= structured.previousVertex
                        structured.prev_mu = prev_mu( :, structured.previousVertex );
                        R_i = R_i + 0.5 * zeta * (( mu_i - A * structured.prev_mu ).^2);
                    end

                    if this.STRUCTURED_NO_VERTEX ~= structured.nextVertex;
                        structured.next_mu = prev_mu( :, structured.nextVertex );
                        R_i = R_i + 0.5 * zeta * (( structured.next_mu - A * mu_i ).^2);
                    end
                end
                new_v = (beta + sqrt( beta^2 + 4 * alpha * R_i))...
                        / (2 * alpha);
                prev_v(:,vertex_i) = new_v ;
            end
        end

        if this.m_descendMode == this.DESCEND_MODE_COORIDNATE_DESCENT 
            iteration_diff = sum(sum((prev_mu - current_mu).^2));
            prev_mu = current_mu;
        end
        if this.m_isCalcObjective
            this.calcObjective( current_mu, prev_v );
        end
    end
    
    iteration.v = prev_v.';
    iteration.mu = current_mu.';

    toc(ticID);
end

%% calcObjective

function calcObjective(this, current_mu, current_v)
    alpha               = this.m_alpha;
    beta                = this.m_beta;
    gamma               = this.m_labeledConfidence;
    zeta                = this.m_zeta;
    numVertices = this.numVertices();
    Logger.log('calcObjective');
    Logger.log(['numVertices = ' num2str(numVertices)]);
    assert(~issparse(this.m_W)); % The calculation is not for sparse matrices.
    objective = 0;
    for vertex_i=1:numVertices
        mu_i = current_mu( :, vertex_i);
        v_i  = current_v ( :, vertex_i);
        %if mod(vertex_i, 100) == 0
        %    disp(vertex_i);
        %end
        for vertex_j=1:numVertices
            w_i_j = this.m_W(vertex_i, vertex_j);
            mu_j    = current_mu( :, vertex_j);
            % Was a bug: v_j     = current_v ( :, vertex_i); %Note the i
            % instead of j
            % Did not affect the objective, since (mu_i-mu_j).^2 should be
            % multiplied by 2(1./v_i + 1/.v_j) (fixed now) = 2./v_i +
            % 2./v_j (was in the bug)
            v_j     = current_v ( :, vertex_j); 
            term = 0.25 * w_i_j * sum((1./v_i + 1 ./ v_j) .* ((mu_i - mu_j).^2));
            objective = objective + term;
        end
        isLabeled_i = this.m_isLabeledVector(vertex_i);
%         isLabeled_i = this.injectionProbability(vertex_i);
        if isLabeled_i
            y_i = this.priorLabelScore( vertex_i, : ).';
            objective = objective + ...
                0.5 * sum((1./v_i + 1/gamma) .* ((mu_i - y_i).^2));
        end
        if this.m_isUsingStructured
            A = this.transitionMatrix();
            structuredPreviousVertex = this.m_structuredInfo.previous(vertex_i);
            if this.STRUCTURED_NO_VERTEX ~= structuredPreviousVertex
               mu_i_prev = current_mu( :, structuredPreviousVertex);
               v_i_prev  = current_v ( :, structuredPreviousVertex);
               G_i = diag( 1./v_i + 1./v_i_prev );
               mu_i_diff = (mu_i - A * mu_i_prev);
               objective = objective + 0.5 * zeta * mu_i_diff.' * G_i * mu_i_diff;
            end
        end
    end
    Logger.log(['Objective (without alpha, beta terms) = ' num2str(objective)]);
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

