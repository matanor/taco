classdef QC < GraphTrunsductionBase
    properties (Access=public)
%         m_mu1;
        m_mu2;
        m_mu3;
    end
    
    methods(Static)
        function r = name()
            r = 'QC';
        end
    end
    
methods (Access=public)

%% run
    
function    result = run( this )
    %QC Quadratic Cost criterion
    % Reference: Semi Supervied Learning book, chapter 11

    tic;

    this.classPriorNormalization();
    this.logParams();
    
    mu2 = this.m_mu2;
    mu3 = this.m_mu3;
    max_iterations      = this.m_num_iterations;
    num_vertices        = this.numVertices();
    num_labels          = this.numLabels();
   
    prev_mu     =  zeros( num_labels, num_vertices );
    current_mu  =  zeros( num_labels, num_vertices );

    normalization = sum(this.m_W, 2)                    ...
                    + mu2 * this.m_isLabeledVector      ...
                    + mu3;

    if this.m_save_all_iterations
        allIterations.mu = zeros( num_labels, num_vertices, max_iterations );
    end

    iteration_diff = Inf;
    diff_epsilon = this.m_diffEpsilon;

    % note iteration index starts from 2
    for iter_i=2:max_iterations

        Logger.log([ '#Iteration = '      num2str(iter_i)...
                     ' iteration_diff = ' num2str(iteration_diff)]);

        if iteration_diff < diff_epsilon
            Logger.log(['converged after ' num2str(iter_i-1) ' iterations']);
            if this.m_save_all_iterations
                allIterations.mu(:,:, iter_i:end) = []; %#ok<STRNU>
            end
            break;
        end

        iteration_diff = 0; %#ok<NASGU>

        for vertex_i=1:num_vertices
            if mod(vertex_i,100000) == 0
                Logger.log(['QC::run. vertex_i = ' num2str(vertex_i)]);
            end

            % neighbours_indices and neighbours_weights are column
            % vectors
            [neighbours_indices, ~, neighbours_weights] = find(this.m_W(:, vertex_i));

            % size (numLabels X numNeighbours)
            neighbours_mu = prev_mu( :, neighbours_indices );  
            
            neighbours_weights  = neighbours_weights.'; % make row vector.
            % This is what repmat does - only without all the time
            % wasting if's. This is equivalent to 
            % neighbours_weights = repmat(neighbours_weights, numLabels, 1)
            % and the size of neighbours_weights will be (numLabels X numNeighbours)
            neighbours_weights = neighbours_weights(ones(num_labels,1),:);
            neighbours_mu_times_weights = neighbours_weights .* neighbours_mu;
            sum_neighbours_mu_times_weights = sum(neighbours_mu_times_weights, 2);

            isLabeled = this.m_isLabeledVector(vertex_i);
            y_i = this.m_priorY(vertex_i,:).';
            current_mu(:,vertex_i) =                    ...
                (sum_neighbours_mu_times_weights        ...
                + isLabeled * mu2 * y_i) ./ normalization(vertex_i);
        end
        
        iteration_diff = sum(sum((prev_mu - current_mu).^2));
        prev_mu        = current_mu;
        
        if this.m_save_all_iterations
            allIterations.mu(:,:,iter_i) = prev_mu;
        end
    end

    if this.m_save_all_iterations
        for iter_i=1:size(allIterations.mu,3)
            iterationResult_mu    = allIterations.mu(:,:,iter_i);
            result.mu(:,:,iter_i) = iterationResult_mu.';
        end 
    else
        result.mu = current_mu.';
    end

    toc;
end

end %     methods (Access=public)

methods (Access=private)

    %% logParams

    function logParams(this)
        paramsString = ...
            [' mu2 = '                  num2str(this.m_mu2) ...
             ' mu3 = '                  num2str(this.m_mu3) ...
             ' maximum iterations = '   num2str(this.m_num_iterations)...
             ' num vertices '           num2str(this.numVertices())];                
        Logger.log(['Running ' this.name() '.' paramsString]);            
    end
    
end % methods (Acess=private)

end

