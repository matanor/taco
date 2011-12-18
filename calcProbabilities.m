function p = calcProbabilities( W, labeledVertices )
%CALCPROBABILITIES Calculate continue, injection and abandon
% probabilities for each vertex. 
% Reference: New regularized algorithms for transductive learning
% Talukdar, P. and Crammer, Koby. pages 4-5.

    numVertices = size(W,  1);
    p.inject    = zeros(numVertices, 1);
    p.continue  = zeros(numVertices, 1);
    p.abandon   = zeros(numVertices, 1);
    beta = 2;
    for vertex_i=1:numVertices
        neighbours = getNeighbours( W, vertex_i );
        transitions = calcTransitions( neighbours.weights );
        entropy = - sum( transitions .* log(transitions) );
        % use log2 ad done is scala code downloaded from http://talukdar.net/
        %cv = log(beta) / log2( beta + exp( entropy) ) ;
        cv = log(beta) / log2( beta + entropy ) ;
        isLabeled = ismember( vertex_i, labeledVertices );
        dv = isLabeled * (1-cv) * sqrt( entropy ) ;
        zv = max( cv + dv, 1 );
        p.continue(vertex_i) = cv / zv;
        p.inject  (vertex_i) = dv / zv;
        p.abandon (vertex_i) = 1 - p.continue(vertex_i) - ...
                               p.inject  (vertex_i);
    end
end