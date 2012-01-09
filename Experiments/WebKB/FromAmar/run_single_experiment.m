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

if ( algorithmParams.makeSymetric ~= 0)
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
     ' alpha = '             num2str(alpha) ...
     ' beta = '              num2str(beta) ...
     ' K = '                 num2str(K) ...
     ' makeSymetric = '       num2str(algorithmParams.makeSymetric)];

 disp(paramsString);

%% get positive and negative labeled vertices

labeledPositive = labeled(:, 1);
labeledNegative = labeled(:, 2);
 
 %% Run algorithm - label propagation

labelPropagation = LP;
Y = labelPropagation.run( w_nn, labeledPositive, labeledNegative );

%% Run algorithm - confidence SSL

cssl = CSSL;
cssl.m_W = w_nn;
cssl.m_num_iterations = numIterations;
cssl.m_alpha = alpha;
cssl.m_beta = beta;
cssl.m_labeledConfidence = labeledConfidence;

numVertices = size(w_nn,1);
numLabels   = size(classToLabelMap,1);
Ylabeled = zeros( numVertices, numLabels);
NEGATIVE = 1; POSITIVE = 2;
Ylabeled( labeledNegative, NEGATIVE ) = 1;
Ylabeled( labeledPositive, POSITIVE ) = 1;

result = cssl.runMulticlass( Ylabeled );


%result = cssl.runBinary...
%    ( labeledPositive, labeledNegative, ...
%      positiveInitialValue,negativeInitialValue);
    
%% Run algorithm - MAD

mad = MAD;
            
params.mu1 = 1;
params.mu2 = 1;
params.mu3 = 1;
params.numIterations = numIterations; %This is an upper bound on the number of iterations
            
labeledVertices = labeled(:);
madResultsSource = mad.run( w_nn, Ylabeled, params, labeledVertices );

mad_results = MAD_Results;
mad_results.set_results( madResultsSource );
        
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
singleRun.set_MAD_results( mad_results );
