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

w_nn = makeSymetric(w_nn);

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
 
%% Run the algorithm - confidence SSL
labeledPositive = labeled(:, 1);
labeledNegative = labeled(:, 2);
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
