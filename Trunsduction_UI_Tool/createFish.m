function fishGraph = createFish()
%% fish

numVerticesInCircle = 24;
fish.W = toeplitz( [ 0;1;zeros(numVerticesInCircle - 3,1);1 ] );
% fish.W = [ 0 1 0 0 0 1;
%              1 0 1 0 0 0;
%              0 1 0 1 0 0;
%              0 0 1 0 1 0;
%              0 0 0 1 0 1;
%              1 0 0 0 1 0];
num_vertices = size(fish.W,1);
fish.v_coordinates = zeros( num_vertices, 4);
verticesRange = 0:(num_vertices - 1);
fish.v_coordinates(:,1) = cos(verticesRange * 2 * pi / num_vertices);
fish.v_coordinates(:,2) = sin(verticesRange * 2 * pi / num_vertices);
fish.text_coordinates = 1.1 * fish.v_coordinates;
labeledInCluster = 1;
fish.labeled.positive = [];
fish.labeled.negative = labeledInCluster;
fish.vertexProperties = struct('name',[],'showText', ...
    num2cell(zeros(num_vertices,1)));

fishGraph = Graph;
fishGraph.loadFromStruct(fish);

newVertexPosition.x = 0;
newVertexPosition.y = 0;
centerVertex = fishGraph.addVertex(newVertexPosition);
for vertex_i = 1:(centerVertex-1)
    fishGraph.addEdge(vertex_i, centerVertex);
end

fishGraph.set_vertexTextOffset(centerVertex, [-0.05 0.12] );
fishGraph.set_showArrow(centerVertex, 1 );

tailPosition.x = -1.5;
tailPosition.y = 0;
tailVertex = fishGraph.addVertex(tailPosition);
clusterEnd = floor(numVerticesInCircle / 2)+1;
fishGraph.addEdge(clusterEnd, tailVertex);
fishGraph.set_vertexTextOffset(tailVertex, [-0.13 -0.15] );
fishGraph.set_vertexTextOffset(clusterEnd, [-0.05 0.1] );

tail1Position.x = -1.5;
tail1Position.y = -0.5;
tail2Position.x = -1.5;
tail2Position.y = 0.5;
tail3Position.x = -2.25;
tail3Position.y = 0;
tail1 = fishGraph.addVertex(tail1Position);
tail2 = fishGraph.addVertex(tail2Position);
tail3 = fishGraph.addVertex(tail3Position);

fishGraph.addEdge(tail1, tailVertex);
fishGraph.addEdge(tail2, tailVertex);
fishGraph.addEdge(tail3, tailVertex);

fishGraph.set_vertexTextOffset(tail1, [-0.1 -0.15] );
fishGraph.set_vertexTextOffset(tail2, [-0.1 +0.15] );
fishGraph.set_vertexTextOffset(tail3, [-0.1 -0.15] );

fishGraph.setVertexLabel(tail1, fishGraph.negativeLabel());
fishGraph.setVertexLabel(tail2, fishGraph.positiveLabel());
fishGraph.setVertexLabel(tail3, fishGraph.positiveLabel());

fishGraph.set_showText(tail1, 1);
fishGraph.set_vertexName(tail1, '(-)');
fishGraph.set_showText(tail2, 1);
fishGraph.set_vertexName(tail2, '(+)');
fishGraph.set_showText(tail3, 1);
fishGraph.set_vertexName(tail3, '(+)');

fishGraph.set_showText(centerVertex, 1);
fishGraph.set_vertexName(centerVertex, 'C');

fishGraph.set_showText(clusterEnd, 1);
fishGraph.set_vertexName(clusterEnd, 'B');

fishGraph.set_showText(tailVertex, 1);
fishGraph.set_vertexName(tailVertex, 'A');

fishGraph.set_showText(labeledInCluster, 1);
fishGraph.set_vertexName(labeledInCluster, '(-)');


end

