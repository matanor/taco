function iteration = confidenceSSL...
    (   W, num_iterations, ...
        labeledPositive     , labeledNegative, ...
        positiveInitialValue, negativeInitialValue, ...
        labeledConfidence, alpha, beta)

    tic;
            
    num_vertices = size(W,1);
    disp(['confidenceSSL. num vertices: ' num2str(num_vertices)]);
	
	iteration.mu = zeros( num_vertices, num_iterations );
    iteration.v = ones( num_vertices, num_iterations );

    labeled.positive = labeledPositive;
    labeled.negative = labeledNegative;
    first_iteration = 1;

    iteration.mu( labeled.positive, first_iteration)  = positiveInitialValue;
    iteration.mu( labeled.negative, first_iteration ) = negativeInitialValue;

    iteration.v( labeled.positive, first_iteration)  = labeledConfidence;
    iteration.v( labeled.negative, first_iteration ) = labeledConfidence;

    %beta = this.beta;
    %alpha = this.alpha;

    % note iteration index starts from 2
    for iter_i = 2:num_iterations

        if ( mod(iter_i, 10) == 0 )
            disp(['#Iteration = ' num2str(iter_i)]);
        end
        prev_mu = iteration.mu( :, iter_i - 1) ;
        prev_v =  iteration.v ( :, iter_i - 1) ;

        for vertex_i=1:num_vertices
            neighbours = find( W(vertex_i, :) ~= 0 );
            neighbours_w = W(vertex_i, neighbours);
            neighbours_w = neighbours_w.'; % make column vector
            ni = sum( neighbours_w );
            neighbours_mu = prev_mu( neighbours );
            neighbours_v  =  prev_v( neighbours );
            B = sum( neighbours_w .* neighbours_mu );
            C = sum( neighbours_w .* neighbours_mu ./ neighbours_v );
            D = sum( neighbours_w ./ neighbours_v );
            %ni = length(neighbours);
            %B = sum( prev_mu( neighbours ) );
            %C = sum( prev_mu( neighbours ) ./ prev_v( neighbours ) );
            %D = sum( 1 ./ prev_v( neighbours ) );
            iteration.mu(vertex_i, iter_i) = ...
                (B + prev_v(vertex_i) * C) / (ni + prev_v(vertex_i) * D);
        end

        iteration.mu( labeled.positive, iter_i)  = positiveInitialValue;
        iteration.mu( labeled.negative,  iter_i ) = negativeInitialValue;

        for vertex_i=1:num_vertices
            neighbours = find( W(vertex_i, :) ~= 0 );
            neighbours_w = W(vertex_i, neighbours);
            neighbours_w = neighbours_w.'; % make column vector
            A = sum ( neighbours_w .* ...
                (prev_mu(vertex_i) - prev_mu( neighbours )).^2 );

            iteration.v(vertex_i, iter_i) = ...
                (beta + sqrt( beta^2 + 4 * alpha * A)) / (2 * alpha);
                %(beta + sqrt( beta^2 + 4 * alpha * A)) / (2 * alpha);
                % matan changed 5.12.11 from 4 to 2.
        end

        iteration.v( labeled.positive, iter_i) = labeledConfidence;
        iteration.v( labeled.negative, iter_i ) = labeledConfidence;

    end

    toc;
	disp('size(iteration.v)=');
	disp(size(iteration.v));
    
end


