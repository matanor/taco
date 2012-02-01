function A = zeroMainDiagonal( A )
%ZEROMAINDIAGONAL zero main diagonal of a matrix

n = size(A,1);
A(1:(n+1):n*n) = 0;

end

