function Yout = ModifiedAdsorption...
    ( W, Y, params, labeledVertices )
%MAD Modified ADsorption
%   W - graph weights
%   Y - prior labeling, its size should be
%        number of vertices X number of labels.
% Reference: New regularized algorithms for transductive learning
% Talukdar, P. and Crammer, Koby. pages 10.

    tic;

    mu1 = params.mu1;
    mu2 = params.mu2;
    mu3 = params.mu3;
    numIterations = params.numIterations;
    
    numVertices = size(W, 1);
    
    disp('Calculating probabilities...');
    p = calcProbabilities(W, labeledVertices);
    disp('done');

    % add dummy label. initialy no vertex is
    % associated with the dummy label.
    Y = [Y zeros(numVertices, 1) ];
    numLabels = size( Y, 2 );
    
    % Line (2) of MAD page 10 in reference 
    
    disp('Calculating M(v)...');
    M = calcM(W, p, params);
    disp('done');
    
    D = zeros( size(Y) );
    r = zeros(numLabels, 1);
    r(end) = 1;
    
    for iter_i=1:numIterations
        
        if ( mod(iter_i, 10) == 0 )
            disp(['#Iteration = ' num2str(iter_i)]);
        end
        
        % line (4) of MAD page 10 in reference 
        for vertex_i=1:numVertices
            Dv = calcDv(W, p, Y, vertex_i);
            D( vertex_i, :) = Dv.';
        end
        
        % lines (5)-(6)-(7) of MAD page 10 in reference 
        for vertex_i = 1:numVertices
            p_inject   = p.inject(vertex_i); 
            p_abandon  = p.abandon(vertex_i); 

            Yv = Y( vertex_i, : ).';
            Dv = D( vertex_i, : ).';
            Mv = M( vertex_i );
            Yv = (1/Mv) * ...
                 (mu1 * p_inject * Yv + ... 
                  mu2 * Dv + ...
                  mu3 * p_abandon * r);
            Y(vertex_i,:) = Yv .';
        end
    end
    
    Yout = Y;
    
    toc;
end

