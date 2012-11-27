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
    
	function R = run( this )

        ticID = tic;
        
        v               = this.m_v;
        mu              = this.m_mu;
        alpha           = this.m_alpha;
        num_iterations  = this.m_num_iterations;

        num_vertices = this.numVertices();
        num_labels   = this.numLabels();
        
        this.displayParams(num_vertices);

        if this.m_save_all_iterations
            allIterations.p = zeros( num_labels, num_vertices, num_iterations );
            allIterations.q = zeros( num_labels, num_vertices, num_iterations );
            allIterations.q(:,:,1) = ones(num_labels, num_vertices);
        end

        % Initialization requirement is that q^{(0)}(y) > 0 for all y (all
        % labels). Page 5 in reference, top right.
        current_q = ones(num_labels, num_vertices);
        current_p = zeros(num_labels, num_vertices);
        
        Logger.log('Adding alpha to main diagonal...');
        
        % Change W = W + alpha * I (page 5, top left).
        if issparse(this.m_W)
            [rows,cols,values] = find(this.m_W);
            mainDiagonalRows   = (1:num_vertices).';
            mainDiagonalCols   = (1:num_vertices).';
            mainDiagonalValues = alpha * ones(num_vertices, 1);
            allRows     = [rows;  mainDiagonalRows];
            allColumns  = [cols;  mainDiagonalCols];
            allValues   = [values;mainDiagonalValues];
            this.m_W = sparse(allRows, allColumns, ...
                              allValues, num_vertices, num_vertices);
        else
            for vertex_i=1:num_vertices
                this.m_W(vertex_i,vertex_i) = ...
                    this.m_W(vertex_i,vertex_i) + alpha;
            end
        end

        iteration_diff = Inf;
        diff_epsilon = this.m_diffEpsilon;

        % note iteration index starts from 2
        for iter_i = 2:num_iterations

            Logger.log([ '#Iteration = '      num2str(iter_i)...
                         ' iteration_diff = ' num2str(iteration_diff)]);
            
            if iteration_diff < diff_epsilon
                Logger.log([  'converged after '   num2str(iter_i-1) ' iterations'...
                        ' iteration_diff = ' num2str(iteration_diff)]);
                if this.m_save_all_iterations
                    allIterations.p(:,:, iter_i:end) = [];
                    allIterations.q(:,:, iter_i:end) = [];
                end
                break;
            end
            
            iteration_diff = 0;

            % Page 5 in reference (see top of this file), top right, see equations

            Logger.log('Updating p...');
            
            % calculate p_i^{(n)} for all i (i.e. all vertices)
            % from q_j^{(n-1)}
            for vertex_i=1:num_vertices

                if ( mod(vertex_i, 100000) == 0 )
                    Logger.log([ 'vertex_i = ' num2str(vertex_i)]);
                end
                
                col = this.m_W(:, vertex_i);
                % neighbours_indices and neighbours_weights are column
                % vectors
                [neighbours_indices, ~, neighbours_weights] = find(col);
                neighbours_weights = neighbours_weights.'; % make row vector
                
                % calculate \beta_i^{(n-1)}(y) for all y (all labels)                
                q_neighbours = current_q(:, neighbours_indices);
                %This is the same as repmat(neighbours_weights.', num_labels, 1);
                neighbours_weights_repmat = neighbours_weights(ones(num_labels, 1), :); 
                beta = -v + mu * sum(neighbours_weights_repmat .* (log( q_neighbours ) - 1), 2);
                
                gamma = v + mu * sum( neighbours_weights );
                
                % from beta (vector) and gamma (scalar) calculate p_i^{(n)}
                p_i = exp( beta / gamma );
                p_i = p_i / sum(p_i); % normalize to probability.
                
                % save the calculation
                iteration_diff = iteration_diff + sum((p_i - current_p(:,vertex_i)).^2);
                current_p(:,vertex_i) = p_i;
            end

            Logger.log('Updating q...');
            
            % calculate q_j^{(n)} for all i (i.e. all vertices)
            % from p_i^{(n)}
            for vertex_i=1:num_vertices
                
                if ( mod(vertex_i, 100000) == 0 )
                    Logger.log([ 'vertex_i = ' num2str(vertex_i)]);
                end
                
                col = this.m_W(:, vertex_i);
                % neighbours_indices and neighbours_weights are column
                % vectors
                [neighbours_indices, ~, neighbours_weights] = find(col);
                neighbours_weights = neighbours_weights.'; % make row vector
                
                isLabeled = this.m_isLabeledVector(vertex_i);
                
                y_i = this.m_priorY( vertex_i, : ).';
                %This is the same as repmat(neighbours_weights.', num_labels, 1);
                neighbours_weights_repmat = neighbours_weights(ones(num_labels, 1), :); 
                p_neighbours = current_p(:, neighbours_indices);

                q_i = isLabeled * y_i + ...
                      mu * sum( neighbours_weights_repmat .* p_neighbours, 2);
                  
                q_i_denominator = isLabeled + mu * sum( neighbours_weights );
                q_i = q_i / q_i_denominator;
                
                % save the calculation
                current_q(:,vertex_i) = q_i;
            end

            if this.m_save_all_iterations
                allIterations.p(:,:, iter_i) = current_p;
                allIterations.q(:,:, iter_i) = current_q;
            end
        end

        if this.m_save_all_iterations
            for iter_i=1:size(allIterations.p,3)
                iterationResult_p  = allIterations.p(:,:,iter_i);
                iterationResult_q  = allIterations.q(:,:,iter_i);
                R.p(:,:,iter_i) = iterationResult_p.';
                R.q(:,:,iter_i) = iterationResult_q.';
            end 
        else
            R.p = current_p.';
            R.q = current_q.';
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

