
function main()

close all;
clear all;
clear classes;

mainObject = MainClass;

%% Graph Structure:
%  v_coordinates -  information about each vertex:
%                   x coordinate.
%                   y coordinate.
%                   Value for mu (mean).
%                   Value for v  (variance).

%% Line graph

line.W = toeplitz( [ 0;1;0;0;0;0;0 ] );
num_vertices = size(line.W,1);
line.v_coordinates = zeros( num_vertices, 4);
line.v_coordinates(:,1) = 0:(num_vertices - 1);
line.labeled.positive = 1;
line.labeled.negative = num_vertices;

%% circle graph

circle.W = toeplitz( [ 0;1;0;0;0;0;0;0;0;1 ] );
% circle.W = [ 0 1 0 0 0 1;
%              1 0 1 0 0 0;
%              0 1 0 1 0 0;
%              0 0 1 0 1 0;
%              0 0 0 1 0 1;
%              1 0 0 0 1 0];
num_vertices = size(circle.W,1);
circle.v_coordinates = zeros( num_vertices, 4);
verticesRange = 0:(num_vertices - 1);
circle.v_coordinates(:,1) = cos(verticesRange * 2 * pi / num_vertices);
circle.v_coordinates(:,2) = sin(verticesRange * 2 * pi / num_vertices);
circle.labeled.positive = 1;
circle.labeled.negative = 5;

%% run 

%mainObject.graph = line;
mainObject.set_graph( circle );
  
mainObject.runAlgorithm();
mainObject.plotGraph(1);

end

