
%% Potter: (~) - X * C * X + B * X + B * X + A = 0

mu1 = [1;0.2;0.5] ;
mu2 = [0.6;1;0.7] ;
Y = mu1 * (mu1.') + mu2 * (mu2.');
%Y = [ 1   0.2 0.8 ;
%      0.2 1   1;
%      0.8 1   1 ];
[Vy,Dy] = eig(Y);
Vy *  Dy * inv(Vy) % => Y

A = Y;
B = 0.5 * eye(3);
C = -eye(3);
M = [B A; 
     C -B];
      
[V,Deig] = eig(M);

m = size(M,1);
b = V(1:(m/2),  [1,3,4]);
c = V((m/2+1):end,[1,3,4]);
X = b * inv(c);
R = - X * C * X + B*X + B * X + A;

%% example from 'A New Solution Method for Quadratic Matrix Equations'

A = [ -4 2;
       0 2 ];
B = [ -5 2;
        1 0 ];
C = [ -6  2;
      -2 -1 ];
D = [ -7 +2;
      -5 -1 ];
    
M = [ B  A;
     -D -C ];
      
[V,Deig] = eig(M);

m = size(M,1);
b = V(1:(m/2),  [3,4]);
c = V((m/2+1):end,[3,4]);
X = b * inv(c);
X1 = [-1 0;
      -2 1 ];
X2 = [ 1 -2;
       3 -2 ];
R = A + B * X + X * C + X * D * X;
R = A + B * X1 + X1 * C + X1 * D * X1;
R = A + B * X2 + X2 * C + X2 * D * X2;

%% I * X^2 + s * I * X + C = 0

mu1 = [20;0.2;0.5] ;
mu2 = [0.6;1;0.7] ;
Y = mu1 * (mu1.') + mu2 * (mu2.');

alpha = 0.01;
beta = 1;
C = - (Y / alpha);
s = - (beta / alpha);
B = s * eye( size(C) );

det = B*B-4*C;
[Vdet, Ddet] = eig(det);
sqrt_det = Vdet * (Ddet.^0.5) * Vdet.';
X = - 0.5 * B + 0.5 * (sqrt_det);

R = X * X + s * X + C;
R2 = alpha * X * X - beta * X -Y;