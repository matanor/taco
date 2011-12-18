function n = getNeighbours( W, vertex_i )
%GETNEIGHBOURS Get the neighbours of a specific vertex.
%   Detailed explanation goes here
        
    neighbours = find( W(vertex_i, :) ~= 0 );
    neighbours_w = W(vertex_i, neighbours);
    neighbours_w = neighbours_w.'; % make column vector

    n.indices = neighbours;
    n.weights = neighbours_w;
end

