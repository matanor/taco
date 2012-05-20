function n = getNeighbours( W, vertex_i )
    col = W(:, vertex_i);
    [neighbours, ~, neighbours_w] = find(col);
    n.indices = neighbours;
    n.weights = neighbours_w;
end

