function experiment = run_webkb_amar...
    (K, numLabeled, numInstancesPerClass, numIterations...
     , showResults)
% %% Load the graph
% 
% load webkb_amar.mat;
% graph = webkb_amar;
% 
% %% select only 2 classes
% [selected] = selectClasses(graph, [1 4]);
% selected.labels (selected.labels == 4) = 2;
% 
% %% Balance the classes
% % numInstancesPerClass = 500;
% 
% [balanced.weights, balanced.labels ] = ...
%     balanceClasses(selected.weights,selected.labels,...
%     numInstancesPerClass);
% 
% isSymetric(balanced.weights);
% 
% %% 
% 
% w = balanced.weights;
% lbls = balanced.labels;
% lbls = lbls - 1;
% lbls(lbls == 0) = -1;
% 
% %% Create K-Nearest Neighbour graph
% % k = 20;
% w_nn = knn(w,K);
% 
% %% Randomly select labeled vertices
% % numLabeled = 50;
% labeledPositive = selectLabeled(lbls, numLabeled, +1);
% labeledNegative = selectLabeled(lbls, numLabeled, -1);
% %labeledPositive = unidrnd(1000, numLabeled, 1) + 3000;
% %labeledNegative = unidrnd(1000, numLabeled, 1) + 2000;

%%
showResults = 1;

%% 

classToLabelMap = [ 1  1;
                    4 -1 ];
                
numClasses = size( classToLabelMap, 1);
%[ graph, labeledPositive,labeledNegative ] = ...
[ graph, labeled ] = ...
    load_graph_amar ...
    ( classToLabelMap, K, numLabeled, ...
      numInstancesPerClass );
  
w_nn = graph.weights;
lbls = graph.labels;

%% Prepare parameters
%numIterations = 50;
positiveInitialValue = +1;
negativeInitialValue = -1;
labeledConfidence = 0.01;
alpha = 1;
beta = 1;

%%
paramsString = ...
    [' labeledConfidence = ' num2str(labeledConfidence) ...
     ' alpha = '    num2str(alpha) ...
     ' beta = '     num2str(beta) ...
     ' K = '     num2str(K) ];

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
%numClasses = length(unique(balanced.labels));
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

%% 
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
    filename = 'results labeled regularized/labeled_high_confidence.fig';
    saveas(gcf, filename);
end

%%

[sortedConfidence,confidenceSortIndex] = sort(final_confidence);
correctSortedAccordingToConfidence = ...
    correct(confidenceSortIndex);
wrong = 1 - correctSortedAccordingToConfidence;
accumulativeLoss = cumsum(wrong);
marginSortedAccordingToConfidence = ...
    margin(confidenceSortIndex);

%% 
if (showResults)
    t = [ 'Results (sorted by confidence).' ...
          paramsString ];
    numRows = 2;
    numCols = 1;
    figure('name', t);
    subplot(numRows,numCols,1);
    plot(accumulativeLoss,  'b');
    title('accumulative loss sorted by final_confidence');
    subplot(numRows,numCols,2);
    plot(sortedConfidence,  'r');
    title('sorted final_confidence');
end

%%
experiment.accumulativeLoss = accumulativeLoss;
experiment.sortedConfidence = sortedConfidence;
experiment.completeResult = result;
experiment.sortedMargin = marginSortedAccordingToConfidence;



