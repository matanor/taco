function C = cartesianProduct( A, B )
%CARTESIANPRODUCT Summary of this function goes here
%   Detailed explanation goes here

if isempty(A)
    C = B;
    return;
end

[rows_A, cols_A] = size(A);
[rows_B, cols_B] = size(B);
assert( cols_B == 1);
C = zeros(rows_A * rows_B, cols_A + 1);
row_i_c = 1;
for row_i_a=1:rows_A
    for row_i_b=1:rows_B
       C(row_i_c, :) = [ A( row_i_a,:) B(row_i_b) ];
       row_i_c = row_i_c + 1;
    end
end

end

