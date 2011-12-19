function experiment = run_webkb_amar...
    (graphFileName, constructionParams,...
     algorithmParams, showResults)

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
 
%% Run the algorithm
labeledPositive = labeled(:, 1);
labeledNegative = labeled(:, 2);
result = confidenceSSL...
    ( w_nn, numIterations, labeledPositive, labeledNegative, ...
        positiveInitialValue,negativeInitialValue, ...
        labeledConfidence, alpha, beta);

%% Get the results of the last iteration (final results)

final_mu = result.mu(:,numIterations);
final_confidence = result.v(:,numIterations);

%% Show final prediction & confidence
if (showResults)
    numVertices = length( final_mu);

    t = [ 'Results (prediction & confidence).' ...
          paramsString ];

    figure('name', t);
    hold on;
    scatter(1:numVertices, final_mu, 'b');
    scatter(1:numVertices, final_confidence, 'r');
    legend('prediction', 'confidence');
    xlabel('vertex #i');

end;

%% Quantize the prediction to the discrete classes
numClasses = size( classToLabelMap, 1);
range = linspace(negativeInitialValue, ...
                 positiveInitialValue, numClasses + 1);

prediction = final_mu ;
classValueMap = [-1; +1];
for range_i = 1:numClasses
    bottom = range(range_i);
    top = range(range_i + 1);
    prediction(bottom <= prediction & prediction < top) = ...
        classValueMap(range_i);
end

%%
correct = (prediction == lbls);
%margin = abs( final_mu - lbls);
margin = final_mu .* lbls;

slashes = find(graphFileName == '\');
lastSlash = slashes(end);
outputFolder = graphFileName(1:lastSlash);

%% Show final margin & confidence
if (showResults)
    numVertices = length( final_mu );

    t = [ 'Results (margin & confidence).' ...
          paramsString ];

    figure('name', t);
    hold on;
    scatter(1:numVertices, final_confidence, 'b');
    scatter(1:numVertices, margin, 'k');
    scatter(labeledPositive, final_confidence(labeledPositive), '+g');
    scatter(labeledPositive, margin(labeledPositive), '+g');
	scatter(labeledNegative, final_confidence(labeledNegative), '+r');
    scatter(labeledNegative, margin(labeledNegative), '+r');
    legend('confidence', 'margin');
    xlabel('vertex #i');    
    % filename = [ 'results labeled regularized/labeled_high_confidence.fig';
    filename = [ outputFolder 'labeled_high_confidence.fig'];
    saveas(gcf, filename);
end

%%

[sortedConfidence,confidenceSortIndex] = sort(final_confidence);
correctSortedAccordingToConfidence = ...
    correct(confidenceSortIndex);
wrong = 1 - correctSortedAccordingToConfidence;
sortedAccumulativeLoss = cumsum(wrong);
marginSortedAccordingToConfidence = ...
    margin(confidenceSortIndex);

%% Show accumulative loss sorted by confidence
if (showResults)
    t = [ 'Results (sorted by confidence).' ...
          paramsString ];
    numRows = 2;
    numCols = 1;
    figure('name', t);
    subplot(numRows,numCols,1);
    plot(sortedAccumulativeLoss,  'b');
    title('accumulative loss sorted by final_confidence');
    subplot(numRows,numCols,2);
    plot(sortedConfidence,  'r');
    title('sorted final_confidence');
end

%%
result.margin = margin;
result.labeledPositive = labeledPositive;
result.labeledNegative = labeledNegative;

experiment.sortedAccumulativeLoss = sortedAccumulativeLoss;
experiment.sortedConfidence = sortedConfidence;
experiment.completeResult = result;
experiment.sortedMargin = marginSortedAccordingToConfidence;



