function singleRun = run_single_experiment...
    (graphFileName, constructionParams, algorithmParams)

%% define the classes we use

classToLabelMap = [ 1  1;
                    4 -1 ];
                
%% extract construction params
                
K                    = constructionParams.K;
numLabeled           = constructionParams.numLabeled;
numInstancesPerClass = constructionParams.numInstancesPerClass;

%%  load the graph

[ graph, labeled ] = load_graph ...
    ( graphFileName, classToLabelMap, K, numLabeled, ...
      numInstancesPerClass );
  
w_nn = graph.weights;
lbls = graph.labels;

if ( constructionParams.makeSymetric ~= 0)
    w_nn = makeSymetric(w_nn);
end

%% Prepare algorithm parameters

positiveInitialValue = +1;
negativeInitialValue = -1;

numIterations     = algorithmParams.numIterations;
labeledConfidence = algorithmParams.labeledConfidence;
alpha             = algorithmParams.alpha;
beta              = algorithmParams.beta;

%% display parameters
paramsString = ...
    [' labeledConfidence = ' num2str(labeledConfidence) ...
     ' alpha = '    num2str(alpha) ...
     ' beta = '     num2str(beta) ...
     ' K = '     num2str(K) ];

 disp(paramsString);

%% get positive and negative labeled vertices

labeledPositive = labeled(:, 1);
labeledNegative = labeled(:, 2);
 
 %% Run algorithm - label propagation

Y = labelPropagation( w_nn, labeledPositive, labeledNegative );

%% Run algorithm - confidence SSL

result = confidenceSSL...
    ( w_nn, numIterations, labeledPositive, labeledNegative, ...
        positiveInitialValue,negativeInitialValue, ...
        labeledConfidence, alpha, beta);
        
%% Create a single run object for results.

singleRun = SingleRun;
singleRun.labeledPositive = labeledPositive;
singleRun.labeledNegative = labeledNegative;
singleRun.correctLabels = lbls;
singleRun.positiveInitialValue = positiveInitialValue;
singleRun.negativeInitialValue = negativeInitialValue;
singleRun.classToLabelMap = classToLabelMap;
singleRun.result = result;
singleRun.LP.Y = Y;
