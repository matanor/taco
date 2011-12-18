function Dv = calcDv( W, p, Y, vertex_i )
%CALCDV Summary of this function goes here
%   Detailed explanation goes here

neighbours = getNeighbours(W, vertex_i);
p_continue = p.continue(vertex_i); 

numLabels = size( Y, 2 );
Dv = zeros( numLabels, 1);

numNeighbours = length(neighbours.indices);
for neighbour_i=1:numNeighbours
    neighbour_weight = neighbours.weights(neighbour_i);
    neighbour_id    = neighbours.indices(neighbour_i);
    outgoing = neighbour_weight;
    incoming = W(neighbour_id, vertex_i);
    p_continue_neighbour = p.continue(neighbour_id);
    avg_weight = p_continue * outgoing + ...
                 p_continue_neighbour * incoming;
    Y_neighbour = Y( neighbour_id, : ).';
    Dv = Dv + avg_weight * Y_neighbour;
end

end

