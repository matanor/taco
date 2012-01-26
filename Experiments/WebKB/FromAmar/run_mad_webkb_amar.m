
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

%% run MAD algorithm
params.mu1 = 1;
params.mu2 = 1;
params.mu3 = 1;
params.maxIterations = numIterations;
params.useGraphHeuristics = 1;

numVertices = size( w_nn_sym, 1 );
Ylabeled = zeros(numVertices, numClasses);
for class_i=1:numClasses
    labeledForClass = labeled(:, class_i);
    Ylabeled(labeledForClass, class_i ) = 1;
end

labeledVertices = labeled(:);

%profile on;
tic;
mad = MAD;
result = mad.run(  w_nn_sym, Ylabeled, params  , labeledVertices);
Y = result.Y(:,:,end);
%profile off;
toc;

%% run CSSLMCF

alpha = 1;
beta = 1;
labeledConfidence = 2;

algorithm = CSSLMC;
algorithm_results = CSSLMC_Result;

algorithm.m_W                 = w_nn_sym;
algorithm.m_num_iterations    = numIterations;
algorithm.m_alpha             = alpha;
algorithm.m_beta              = beta;
algorithm.m_labeledConfidence = labeledConfidence;

algorithmResultsSource = algorithm.run( Ylabeled );

algorithm_results.set_results(algorithmResultsSource);

Y_final = algorithmResultsSource.mu(:,:,end);
algorithmResultsSourceUnlabaled = algorithmResultsSource;

numUnlabeled = numVertices - length(labeledVertices);
numLabels = size(classToLabelMap, 1);

algorithmResultsSourceUnlabaled.mu(labeledVertices,:,:) = [];

for iter_i=1:50 
    figure; 
    scatter(1:numUnlabeled, algorithmResultsSourceUnlabaled.mu(:,1,iter_i));
end
Sigma_final = algorithmResultsSource.sigma(:,:,:,end);

Y_final_norm = Y_final;
for vertex_i=1:numVertices
    for label_i = 1:numLabels
        Y_final_norm(vertex_i, label_i) = ...
            Y_final(vertex_i,label_i) / Sigma_final(vertex_i,label_i,label_i);
    end
end

[~, prediction] = max(Y_final,[],2);
scatter(1:numVertices, prediction);

isCorrect = (prediction == lbls);
isWrong = 1 - isCorrect;
sum(isWrong)

%%
resultsDir = 'C:\technion\theses\Experiments\WebKB\results\';
%folderName = '2012_01_24 L2 regularization';
folderName = '2012_01_24 mad complete compare with CSSLMC.';
mkdir(resultsDir,folderName);

%%
figureName = 'Mad prediction';
figure('name',figureName);
Y_NoDummy = Y(:,1:numClasses);
[~, prediction] = max(Y_NoDummy,[],2);
hold on;
scatter(1:numVertices, prediction);
plot(lbls, 'r');
hold off;
filename = [resultsDir folderName '/output.prediction.fig'];
saveas(gcf,filename); 
close(gcf);

isCorrect = (prediction == lbls);
isWrong = 1 - isCorrect;
numMistakes = sum(isWrong);

%%
figureName = 'Mad output';
figure('name',figureName);
title([figureName '. numMistakes = ' num2str(numMistakes)]); 
hold on;
colors = [ 'b','r','g','k'];
for class_i=1:numClasses
    color = colors(class_i);
    scatter(1:numVertices, Y(:, class_i), color);
end
legend('1','2','3','4');
hold off;

filename = [resultsDir folderName '/output.scores.fig'];
saveas(gcf,filename); 
close(gcf);