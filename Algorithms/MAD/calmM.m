function M = calcM( W, p, params )
%CALCM Summary of this function goes here
%   Detailed explanation goes here

mu1 = params.mu1;
mu2 = params.mu2;
mu3 = params.mu3;

numVertices = size(W, 1);
M = zeros( numVertices, 1);

for vertex_i=1:numVertices
    p_inject   = p.inject(vertex_i); 
    p_continue = p.continue(vertex_i); 
    neighbours = getNeighbours(W, vertex_i);

    numNeighbours = length(neighbours.indices);
    sumNeighbours = 0;
    for neighbour_i=1:numNeighbours
        neighbour_weight = neighbours.weights(neighbour_i);
        neighbour_idx    = neighbours.indices(neighbour_i);
        outgoing = neighbour_weight;
        incoming = W(neighbour_idx, vertex_i);
        p_continue_neighbour = p.continue(neighbour_idx);
        sumNeighbours = sumNeighbours + ...
                        p_continue * outgoing + ...
                        p_continue_neighbour * incoming;
    end
    M (vertex_i) =  mu1 * p_inject + ...
                    mu2 * sumNeighbours + ...
                    mu3;
end
    
end

