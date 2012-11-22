classdef CSSLMC < CSSLBase

methods (Access=public)
    
%% run
    
function R = run( this )

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
    objectiveType       = this.m_objectiveType;
    
    % save flags in local boolean variables - for performance (this is stupid but fast)
    isStructuresTransitionMatrix = (this.m_structuredTermType == CSSLBase.STRUCTURED_TRANSITION_MATRIX);
    isStrucutredLabelSimilarity  = (this.m_structuredTermType == CSSLBase.STRUCTURED_LABELS_SIMILARITY);
    isStructuredAnyKind          = isStrucutredLabelSimilarity || isStructuresTransitionMatrix ;
    isObjectiveHarmonicMean      = (objectiveType == CSSLBase.OBJECTIVE_HARMONIC_MEAN);
    isObjectiveMultiplicative    = (objectiveType == CSSLBase.OBJECTIVE_MULTIPLICATIVE);
    isObjectiveWeightsUncertainty= (objectiveType == CSSLBase.OBJECTIVE_WEIGHTS_UNCERTAINTY);
    
    this.displayParams(CSSLMC.name());

    num_vertices = this.numVertices();
    num_labels   = this.numLabels();

    prev_mu     =  zeros( num_labels, num_vertices );
    current_mu  =  zeros( num_labels, num_vertices );
    
    if 0 == isUsingSecondOrder
        initFactor_v = (beta / alpha);
    else
        initFactor_v = 1;
    end
    
    prev_v      =  ones ( num_labels, num_vertices ) * initFactor_v;
    current_v   =  ones ( num_labels, num_vertices ) * initFactor_v;

    % Note: W is assumed symmetric so only upper triangular part is
    % considered
    [vertex_rows, vertex_cols, ~] = find(triu(this.m_W));
    num_edges = length(vertex_rows);
    % Create a mapping such that vertexToEdgeMap(i,j) gives the index of
    % the edge between v_i and v_j, make the map symmetric.
    vertexToEdgeMap = sparse([vertex_rows vertex_cols], ...
                             [vertex_cols vertex_rows], ...
                             [1:num_edges 1:num_edges]);

    % Size is (num_labels X num_edges )
    prev_edges_v = ones ( num_labels, num_edges ) * initFactor_v;
    curr_edges_v = prev_edges_v;
    
    % create a map that labeledToPriorEdgeMap(vertex_i) = edge of
    % uncertainty parameter for v_i in prev_edges_prior_v
    num_labeled = sum(this.m_isLabeledVector);
    [labeled_indices, ~, ~] = find(this.m_isLabeledVector);
    labeledToPriorEdgeMap = sparse(labeled_indices, ones(num_labeled,1), 1:num_labeled, num_vertices, 1);
    
    % Size is (num_labels X num_labeled_vertices)
    prev_edges_prior_v = ones(num_labels, num_labeled) * initFactor_v;
    curr_edges_prior_v = prev_edges_prior_v;

    if this.m_save_all_iterations
        allIterations.mu     = zeros( num_labels, num_vertices, num_iterations );
        allIterations.v      = ones ( num_labels, num_vertices, num_iterations ) * initFactor_v;
        allIterations.edges_v= ones ( num_labels, num_edges,    num_iterations ) * initFactor_v;
    end

    this.prepareGraph();
    
    iteration_diff = 10^1000;
%     diff_epsilon = 0.0001;
    diff_epsilon = 0.0000001;

    %if this.DESCEND_MODE_AM == this.m_descendMode
     %   vertexUpdateOrder = randperm(num_vertices);
    %else
        vertexUpdateOrder = 1:num_vertices;
    %end
    
    A = this.transitionMatrix();
    column_sum = sum(A,1);
    rows_sum = sum(A,2);
    if max(abs(column_sum - 1)) < 10^-8
        Logger.log('CSSLMC::run. Transition matrix column sum to 1. Transposing...');    
        A = A.';
    end
    
    if max(abs(rows_sum - 1)) < 10^-8
        Logger.log('CSSLMC::run. Transition matrix rows sum to 1.');    
    end
    % pre compute all you can
    labelSimilarityMatrix = A;
    zeta_times_labelSimilarityMatrix = zeta * labelSimilarityMatrix ;
    labelSimilarityMatrix_transposed = labelSimilarityMatrix.';
    zeta_times_labelSimilarityMatrix_transposed = zeta * labelSimilarityMatrix_transposed;
    zeta_times_A_tran = zeta * A.';
    
    % a different constant factor is involved in the update of the uncertainty
    % parameter labeled term. precompute it.
    
    if isObjectiveHarmonicMean
        isLabeledFactor = 1;
    else
        isLabeledFactor = 1 / gamma;
    end
    
    % note iteration index starts from 2
    for iter_i = 2:num_iterations
        Logger.log([ '#Iteration = ' num2str(iter_i)...
                     ' iteration_diff = ' num2str(iteration_diff)]);
        if iteration_diff < diff_epsilon
            Logger.log([  'converged after '   num2str(iter_i-1) ' iterations'...
                          ' iteration_diff = ' num2str(iteration_diff)]);
            if this.m_save_all_iterations
                allIterations.mu(:,:, iter_i:end) = [];
                allIterations.v(:,:, iter_i:end) = [];
                allIterations.edges_v(:,:, iter_i:end) = [];
            end
            break;
        end
        iteration_diff = 0;
        
        Logger.log('Updating first order...');
        
        for vertex_i=vertexUpdateOrder
            if ( mod(vertex_i, 100000) == 0 )
                Logger.log([ 'vertex_i = ' num2str(vertex_i)]);
            end

            col = this.m_W(:, vertex_i);
            [neighbours_indices, ~, neighbours_weights] = find(col);
    
            isLabeled = this.m_isLabeledVector(vertex_i);
            neighbours_mu = prev_mu( :, neighbours_indices );
            numNeighbours = length(neighbours_indices);
            % neighbours_v: matrix size (num_labels X num_neighbours)
            % Each column is uncertainty for all neighbours, for a
            % given class. 
            if 0 == isObjectiveWeightsUncertainty
                neighbours_v  = prev_v ( :, neighbours_indices );
                v_i           = prev_v ( :, vertex_i);
            else
                neighbouring_edges_indices = vertexToEdgeMap(vertex_i, neighbours_indices);
                neighbours_v               = prev_edges_v( :, neighbouring_edges_indices );
            end
            sum_K_i_j = zeros(num_labels, 1);
            Q_i       = zeros(num_labels, 1);
            for neighbour_i=1:numNeighbours
                single_neighbour_mu = neighbours_mu(:,neighbour_i);
                single_neighbour_v  = neighbours_v (:,neighbour_i);
                w_i_j = neighbours_weights(neighbour_i);
                
                % K_i_j should be vector of size (num_labels X 1)
                if isObjectiveHarmonicMean
                    K_i_j = w_i_j * ((1./single_neighbour_v) + (1./v_i));
                elseif isObjectiveMultiplicative
                    K_i_j = w_i_j * ((1./single_neighbour_v) .* (1./v_i));
                elseif isObjectiveWeightsUncertainty
                    K_i_j = w_i_j ./ single_neighbour_v;
                else
                    Logger.log('CSSLMC::Run. Error unknown objective type');
                end
                
                sum_K_i_j = sum_K_i_j + ...
                    K_i_j .* single_neighbour_mu;
                Q_i = Q_i + K_i_j;
            end
            % P_i size is (num_labels X 1)
            if isObjectiveHarmonicMean
                P_i = isLabeled * ( 1./v_i + 1 / gamma );
            elseif isObjectiveMultiplicative
                P_i = isLabeled * ( (1./v_i) * (1 / gamma) );
            elseif isObjectiveWeightsUncertainty
                priorEdgeIndex = labeledToPriorEdgeMap(vertex_i);
                if 1 == isLabeled
                    P_i = (1 / gamma) * prev_edges_prior_v(:,priorEdgeIndex);
                else
                    P_i = zeros(num_labels,1);
                end
            end
            % y_i size is (num_labels X 1)
            y_i = this.m_priorY(vertex_i,:).';
            numerator   = sum_K_i_j + (P_i .* y_i); % .* because P_i is only main diagonal
            denominator = diag(Q_i + P_i + isUsingL2Regularization * 1);
            
            if isStructuresTransitionMatrix
                structuredPreviousVertex = this.m_structuredInfo.previous(vertex_i);
                if this.STRUCTURED_NO_VERTEX ~= structuredPreviousVertex
                    st ructuredPrev_mu = prev_mu( :, structuredPreviousVertex );
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
            
            if isStrucutredLabelSimilarity
                structuredPreviousVertex = this.m_structuredInfo.previous(vertex_i);
                if this.STRUCTURED_NO_VERTEX ~= structuredPreviousVertex
                    structuredPrev_mu = prev_mu( :, structuredPreviousVertex );
                    structuredPrev_v  = prev_v ( :, structuredPreviousVertex);
                    % This will create a matrix with element r,s equals to
                    % v_{i,r} + v_{i-1,s}
                    structuredPrev_v = structuredPrev_v.'; % make row vector
                    prev_uncertainty_matrix = ...
                        structuredPrev_v(ones(1, num_labels),:) + v_i(:, ones(num_labels, 1));
                    % note the transpose on the label similarity matrix
                    prev_weights_matrix = zeta_times_labelSimilarityMatrix_transposed .* prev_uncertainty_matrix;
                    
                    numerator = numerator + prev_weights_matrix * structuredPrev_mu;
                    denominator = denominator + diag(sum(prev_weights_matrix,2));    
                end
                
                structuredNextVertex     = this.m_structuredInfo.next(vertex_i);
                if this.STRUCTURED_NO_VERTEX ~= structuredNextVertex;
                    structuredNext_mu = prev_mu( :, structuredNextVertex);
                    structuredNext_v  = prev_v ( :, structuredNextVertex).'; % make row vector
                    % This will create a matrix with element r,s equals to
                    % v_{i,r} + v_{i+1,s}
                    next_uncertainty_matrix = ...
                        structuredNext_v(ones(1, num_labels),:) + v_i(:, ones(num_labels, 1));
                    % note NO transpose on the label similarity matrix
                    next_weights_matrix = zeta_times_labelSimilarityMatrix .* next_uncertainty_matrix;
                    
                    numerator = numerator + ...
                        next_weights_matrix * structuredNext_mu;
                    denominator = denominator + diag(sum(next_weights_matrix,2));
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
                                 sum((current_mu(:, vertex_i) - prev_mu(:,vertex_i)).^2);
                prev_mu(:,vertex_i) = current_mu( :, vertex_i);
            end
        end % end first order update loop

        if this.m_descendMode == this.DESCEND_MODE_2 
            iteration_diff = sum(sum((prev_mu - current_mu).^2));
            prev_mu = current_mu ;
        end
        
        Logger.log('Updating second order...');

        if isUsingSecondOrder
            if isObjectiveWeightsUncertainty
                [vertex_rows, vertex_cols, weights_i_j] = find(triu(this.m_W));
                for edge_i=1:num_edges
                    % vertexToEdgeMap(i,j) gives the index of the edge between v_i and v_j
                    vertex_i = vertex_rows(edge_i);
                    vertex_j = vertex_cols(edge_i);
                    prev_mu_i = prev_mu( :, vertex_i );
                    prev_mu_j = prev_mu( :, vertex_j );
                    R_i_j = weights_i_j(edge_i) * (prev_mu_i - prev_mu_j).^2;
                    edge_update_index = vertexToEdgeMap(vertex_i,vertex_j);
                    curr_edges_v(:,edge_update_index) = ...
                        (beta + sqrt( beta^2 + alpha * R_i_j)) / (2 * alpha);
                end
                for labeled_i=labeled_indices.'
                    prev_mu_i = prev_mu( :, labeled_i );
                    y_i  = this.m_priorY(labeled_i,:).';
                    R_i = (prev_mu_i - y_i).^2;
                    % labeledToPriorEdgeMap(v_i) = edge of
                    % uncertainty parameter for v_i in prev_edges_prior_v
                    priorEdgeIndex = labeledToPriorEdgeMap(labeled_i);
                    curr_edges_prior_v(:,priorEdgeIndex) = ...
                        (beta + sqrt( beta^2 + 2 * alpha / gamma * R_i)) / (2 * alpha);
                end
            else
                for vertex_i=1:num_vertices
                    if ( mod(vertex_i, 100000) == 0 )
                        Logger.log([ 'vertex_i = ' num2str(vertex_i)]);
                    end
                    isLabeled = this.m_isLabeledVector(vertex_i);
                    col = this.m_W(:, vertex_i);
                    [neighbours_indices, ~, neighbours_weights] = find(col);

                    y_i  = this.m_priorY(vertex_i,:).';
                    mu_i = prev_mu(:,vertex_i);
                    numNeighbours = length( neighbours_indices );
                    neighbours_mu = prev_mu( :, neighbours_indices );
                    neighbours_v  = prev_v ( :, neighbours_indices );
                    neighboursSquaredDiff = zeros(num_labels, numNeighbours);
                    for neighbour_i=1:numNeighbours
                        if isObjectiveHarmonicMean
                            neighboursSquaredDiff(:,neighbour_i) = ...
                                neighbours_weights(neighbour_i) * ...
                                    ((mu_i - neighbours_mu(:,neighbour_i)).^2);
                        else
                            neighboursSquaredDiff(:,neighbour_i) =         ...
                                    neighbours_weights(neighbour_i) *      ...
                                    (1./neighbours_v(:,neighbour_i)) .*     ...
                                    ((mu_i - neighbours_mu(:,neighbour_i)).^2);
                        end
                    end

                    R_i = 0.5 * sum(neighboursSquaredDiff,2);

                    if isLabeled
                       R_i = R_i +  0.5 * isLabeledFactor * ((mu_i - y_i).^2);
                    end

                    if isStructuredAnyKind
                        structured.previousVertex = this.m_structuredInfo.previous(vertex_i);
                        structured.nextVertex     = this.m_structuredInfo.next(vertex_i);
                    end

                    if isStructuresTransitionMatrix
                        if this.STRUCTURED_NO_VERTEX ~= structured.previousVertex
                            structured.prev_mu = prev_mu( :, structured.previousVertex );
                            R_i = R_i + 0.5 * zeta * (( mu_i - A * structured.prev_mu ).^2);
                        end

                        if this.STRUCTURED_NO_VERTEX ~= structured.nextVertex;
                            structured.next_mu = prev_mu( :, structured.nextVertex );
                            R_i = R_i + 0.5 * zeta * (( structured.next_mu - A * mu_i ).^2);
                        end
                    end

                    if isStrucutredLabelSimilarity
                        if this.STRUCTURED_NO_VERTEX ~= structured.previousVertex
                            structured.prev_mu = prev_mu( :, structured.previousVertex ).'; % make row vector
                            prev_difference_matrix = ...
                                structured.prev_mu(ones(1, num_labels),:) - mu_i(:, ones(num_labels, 1));
                            % note the transpose on the label similarity matrix
                            prev_weighted_difference = labelSimilarityMatrix_transposed .* (prev_difference_matrix.^2);
                            R_i = R_i + 0.5 * zeta * sum(prev_weighted_difference,2);
                        end

                        if this.STRUCTURED_NO_VERTEX ~= structured.nextVertex;
                            structured.next_mu = prev_mu( :, structured.nextVertex ).'; % make row vector
                            next_difference_matrix = ...
                                structured.next_mu(ones(1, num_labels),:) - mu_i(:, ones(num_labels, 1));
                            next_weighted_difference = labelSimilarityMatrix .* (next_difference_matrix.^2);
                            R_i = R_i + 0.5 * zeta * sum(next_weighted_difference,2);
                        end
                    end

                    new_v = (beta + sqrt( beta^2 + 4 * alpha * R_i))...
                            / (2 * alpha);
                    current_v(:, vertex_i) = new_v ;

                    if this.DESCEND_MODE_AM == this.m_descendMode
                        prev_v(:,vertex_i) = current_v( :, vertex_i);
                    end
                end % end second order update loop
            end % else (! isObjectiveWeightsUncertainty )
        end % end if using second order

        if this.m_descendMode == this.DESCEND_MODE_COORIDNATE_DESCENT 
            iteration_diff = sum(sum((prev_mu - current_mu).^2));
            prev_mu             = current_mu;
            prev_v              = current_v;
            prev_edges_v        = curr_edges_v;
            prev_edges_prior_v  = curr_edges_prior_v;
        end
        % descend mode 2 - current mu already updated after finishing mu
        % update loop
        if this.m_descendMode == this.DESCEND_MODE_2 
            prev_v              = current_v;
            prev_edges_v        = curr_edges_v;
            prev_edges_prior_v  = curr_edges_prior_v;
        end
        if this.m_save_all_iterations
            allIterations.mu     ( :, :, iter_i)    = current_mu;
            allIterations.v      ( :, :, iter_i)    = current_v;
            allIterations.edges_v( :, :, iter_i)    = curr_edges_v;
        end
        if this.m_isCalcObjective
            this.calcObjective( current_mu, current_v );
        end
    end % end loop over all iterations
    
    if this.m_save_all_iterations
        for iter_i=1:size(allIterations.mu,3)
            iterationResult_mu      = allIterations.mu(:,:,iter_i);
            iterationResult_v       = allIterations.v(:,:,iter_i);
            iterationResult_edges_v = allIterations.edges_v(:,:,iter_i);
            R.mu      (:,:,iter_i) = iterationResult_mu.';
            R.v       (:,:,iter_i) = iterationResult_v.';
            R.edges_v (:,:,iter_i) = iterationResult_edges_v.';
        end
    else
        R.v               = current_v.';
        R.mu              = current_mu.';
        R.edges_v         = curr_edges_v.';
    end
    R.vertexToEdgeMap = vertexToEdgeMap;

    toc(ticID);
end

%% calcObjective
% when cnosidering structured term - this is out of date.

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
    
    isStructuresTransitionMatrix = (this.m_structuredTermType == CSSLBase.STRUCTURED_TRANSITION_MATRIX);
    
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
        if isStructuresTransitionMatrix
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

