function w = knn( w, K )
%K_NN_GRAPH Create K nearest neighbour graph
%   w - symetric weights metrix describing the graph.
%   K - create a K - NN graph.
%   This will zero all N-K smallest values per each row.

% Sort each row in W. Get the indices for the sort.
 [~,j] = sort(w, 2);
 n = size(w,1);
% Get indices for N-K smallest values per row.
 small_nums_indexes = j( :, 1:(n - K) );
% Zero N-K smallest values for every row.
for row=1:n
   small_nums_indexes_in_row = small_nums_indexes(row,:);
   w( row,  small_nums_indexes_in_row  ) = 0;
end;

end

