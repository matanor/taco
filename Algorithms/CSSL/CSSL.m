classdef CSSL < handle

    properties (Access=public)
        m_W;
        m_num_iterations;
        m_alpha;
        m_beta;
        m_labeledConfidence;
    end
    
    methods (Access=public)
        
        function iteration = runBinary( this, ...
                labeledPositive     , labeledNegative,...
                positiveInitialValue, negativeInitialValue )

        tic;
        
        alpha               = this.m_alpha;
        beta                = this.m_beta;
        num_iterations      = this.m_num_iterations;
        labeledConfidence   = this.m_labeledConfidence;
        
        gamma = labeledConfidence;
        num_vertices = size(this.m_W,1);
        disp(['confidenceSSL. num vertices: ' num2str(num_vertices)]);

        iteration.mu = zeros( num_vertices, num_iterations );
        iteration.v  = ones ( num_vertices, num_iterations );

        labeled.positive = labeledPositive;
        labeled.negative = labeledNegative;

        % note iteration index starts from 2
        for iter_i = 2:num_iterations

            if ( mod(iter_i, 10) == 0 )
                disp(['#Iteration = ' num2str(iter_i)]);
            end
            prev_mu = iteration.mu( :, iter_i - 1) ;
            prev_v =  iteration.v ( :, iter_i - 1) ;

            for vertex_i=1:num_vertices

                isPositive = ismember(vertex_i, labeled.positive);
                isNegative = ismember(vertex_i, labeled.negative);
                isLabeled = isPositive | isNegative;
                y_i =   isPositive * positiveInitialValue + ...
                        isNegative * negativeInitialValue;

                neighbours = find( this.m_W(vertex_i, :) ~= 0 );
                neighbours_w = this.m_W(vertex_i, neighbours);
                neighbours_w = neighbours_w.'; % make column vector

                ni = sum( neighbours_w ) + isLabeled;
                neighbours_mu = prev_mu( neighbours );
                neighbours_v  =  prev_v( neighbours );
                B = sum( neighbours_w .* neighbours_mu ) ...
                    + isLabeled * y_i;
                C = sum( neighbours_w .* neighbours_mu ./ neighbours_v ) ...
                    + isLabeled * (y_i / gamma) ;
                D = sum( neighbours_w ./ neighbours_v ) ...
                    + isLabeled / gamma;

                new_mu =    (B + prev_v(vertex_i) * C) / ...
                            (ni + prev_v(vertex_i) * D);
                iteration.mu(vertex_i, iter_i) = new_mu ;
            end

            for vertex_i=1:num_vertices
                isPositive = ismember(vertex_i, labeled.positive);
                isNegative = ismember(vertex_i, labeled.negative);
                isLabeled = isPositive | isNegative;
                y_i =   isPositive * positiveInitialValue + ...
                        isNegative * negativeInitialValue;

                neighbours = find( this.m_W(vertex_i, :) ~= 0 );
                neighbours_w = this.m_W(vertex_i, neighbours);
                neighbours_w = neighbours_w.'; % make column vector

                mu_i = prev_mu(vertex_i);
                neighbours_mu = prev_mu( neighbours );
                A = sum ( neighbours_w .* ...
                    (mu_i  - neighbours_mu).^2 )...
                    + isLabeled * (mu_i -y_i)^2;

                new_v = (beta + sqrt( beta^2 + 2 * alpha * A))...
                        / (2 * alpha);
                iteration.v(vertex_i, iter_i) = new_v ;

                    %(beta + sqrt( beta^2 + 4 * alpha * A)) / (2 * alpha);
                    % matan changed 5.12.11 from 4 to 2.
            end
        end

        toc;
        disp('size(iteration.v)=');
        disp(size(iteration.v));
    
        end

	function iteration = runMulticlass( this, labeledY)

        tic;
        
        alpha               = this.m_alpha;
        beta                = this.m_beta;
        num_iterations      = this.m_num_iterations;
        gamma               = this.m_labeledConfidence;
        
        num_vertices = size(labeledY,1);
        num_labels   = size(labeledY,2);
        disp(['confidenceSSL (multiclass). num vertices: ' num2str(num_vertices)]);

        iteration.mu = zeros( num_vertices, num_labels, num_iterations );
        iteration.v  = ones ( num_vertices, num_labels, num_iterations );

        %isLabeled = max(labeledY, [], 2);
        
        %labeled.positive = labeledPositive;
        %labeled.negative = labeledNegative;

        % note iteration index starts from 2
        for iter_i = 2:num_iterations

            if ( mod(iter_i, 10) == 0 )
                disp(['#Iteration = ' num2str(iter_i)]);
            end
            prev_mu = iteration.mu( :, :, iter_i - 1) ;
            prev_v =  iteration.v ( :, :, iter_i - 1) ;

            for vertex_i=1:num_vertices

                for label_i = 1:num_labels
                    %isPositive = ismember(vertex_i, labeled.positive);
                    %isNegative = ismember(vertex_i, labeled.negative);
                    %isLabeled = isPositive | isNegative;
                    %y_i =   isPositive * positiveInitialValue + ...
                            %isNegative * negativeInitialValue;

                    y_i = labeledY( vertex_i, label_i );
                    isLabeled = (y_i ~=0);
                    
                    neighbours = getNeighbours( this.m_W, vertex_i);
                    %neighbours = find( this.m_W(vertex_i, :) ~= 0 );
                    %neighbours_w = this.m_W(vertex_i, neighbours);
                    %neighbours_w = neighbours_w.'; % make column vector

                    ni = sum( neighbours.weights ) + isLabeled;
                    neighbours_mu = prev_mu( neighbours.indices, label_i );
                    neighbours_v  = prev_v ( neighbours.indices, label_i );
                    B = sum( neighbours.weights .* neighbours_mu ) ...
                        + isLabeled * y_i;
                    C = sum( neighbours.weights .* neighbours_mu ./ neighbours_v ) ...
                        + isLabeled * (y_i / gamma) ;
                    D = sum( neighbours.weights ./ neighbours_v ) ...
                        + isLabeled / gamma;

                    new_mu =    (B + prev_v(vertex_i,label_i) * C) / ...
                                (ni + prev_v(vertex_i,label_i) * D);
                    iteration.mu(vertex_i, label_i, iter_i) = new_mu ;
                end
            end

            for vertex_i=1:num_vertices
                %isPositive = ismember(vertex_i, labeled.positive);
                %isNegative = ismember(vertex_i, labeled.negative);
                %isLabeled = isPositive | isNegative;
                %y_i =   isPositive * positiveInitialValue + ...
                %        isNegative * negativeInitialValue;
                
                for label_i=1:num_labels
                    y_i = labeledY( vertex_i, label_i );
                    isLabeled = (y_i ~=0);

                    neighbours = getNeighbours( this.m_W, vertex_i);
                    %neighbours = find( this.m_W(vertex_i, :) ~= 0 );
                    %neighbours_w = this.m_W(vertex_i, neighbours);
                    %neighbours_w = neighbours_w.'; % make column vector

                    mu_i = prev_mu(vertex_i,label_i);
                    neighbours_mu = prev_mu( neighbours.indices, label_i );
                    A = sum ( neighbours.weights .* ...
                        (mu_i  - neighbours_mu).^2 )...
                        + isLabeled * (mu_i -y_i)^2;

                    new_v = (beta + sqrt( beta^2 + 2 * alpha * A))...
                            / (2 * alpha);
                    iteration.v(vertex_i, label_i, iter_i) = new_v ;
                end

                    %(beta + sqrt( beta^2 + 4 * alpha * A)) / (2 * alpha);
                    % matan changed 5.12.11 from 4 to 2.
            end
        end

        toc;
        disp('size(iteration.v)=');
        disp(size(iteration.v));
    
        end
    end % methods (Access=public)
    
    methods(Static)
       function r = name()
           r = 'CSSL';
       end
    end % methods(Static)
    
end

