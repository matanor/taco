
%% 
numLabeled = 10;
numInstancesPerClass = 0;
numIterations = 50;
K = 1000;

%% 

CLASS_VALUE = 1;
LABEL_VALUE = 2;

classToLabelMap = [ 1  1;
                    2  2;
                    3  3;
                    4  4];
graphFileName = 'C:\technion\theses\Experiments\WebKB\data\From Amar\webkb_amar.mat';
                
numClasses = size( classToLabelMap, 1);
[ graph, labeled ] = load_graph ...
    ( graphFileName, classToLabelMap, K, numLabeled, ...
      numInstancesPerClass );
  
w_nn = graph.weights;
lbls = graph.labels;

%%
isSymetric(w_nn);
w_nn_sym = makeSymetric(w_nn);
isSymetric(w_nn_sym);

%%
params.mu1 = 1;
params.mu2 = 1;
params.mu3 = 1;
params.numIterations = numIterations;

numVertices = size( w_nn_sym, 1 );
Y = zeros(numVertices, numClasses);
for class_i=1:numClasses
    labeledForClass = labeled(:, class_i);
    Y(labeledForClass, class_i ) = 1;
end

labeledVertices = labeled(:);

%profile on;
mad = MAD;
result = mad.run(  w_nn_sym, Y, params  , labeledVertices);
Y = result.Y(:,:,end);
%profile off;

%%
figure('name','Mad output');
hold on;
colors = [ 'b','r','g','k'];
for class_i=1:numClasses
    color = colors(class_i);
    scatter(1:numVertices, Y(:, class_i), color);
end
legend('1','2','3','4');
hold off;

filename = 'results mad/output.scores.fig';
saveas(gcf,filename); 

%%
Y_NoDummy = Y(:,1:numClasses);
[~, prediction] = max(Y_NoDummy,[],2);
scatter(1:numVertices, prediction);

isCorrect = (prediction == lbls);
isWrong = 1 - isCorrect;
sum(isWrong);