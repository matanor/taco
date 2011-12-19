function showResults( experiment, figuresToShow, experimentID )
%SHOWRESULTS Summary of this function goes here
%   Detailed explanation goes here

%%

algorithmOutput     = experiment.result.completeResult(1);
algorithmParams     = experiment.params.algorithmParams;
constructionParams  = experiment.params.constructionParams;

%% extract parameters

% numIterations       = algorithmParams.numIterations; 
labeledConfidence   = algorithmParams.labeledConfidence;
alpha               = algorithmParams.alpha;
beta                = algorithmParams.beta;
K                   = constructionParams.K;

paramsString = ...
    [' labeledConfidence = ' num2str(labeledConfidence) ...
     ' alpha = '    num2str(alpha) ...
     ' beta = '     num2str(beta) ...
     ' K = '        num2str(K) ...
     ' exp ID = '   num2str(experimentID)];

%% Get the results of the last iteration (final results)

final_mu = algorithmOutput.mu(:,end);
final_confidence = algorithmOutput.v(:,end);

%% Show final prediction & confidence
if (figuresToShow.predictionAndConfidence) 
    numVertices = length( final_mu);

    t = [ 'Results (prediction & confidence).' paramsString ];

    figure('name', t);
    hold on;
    scatter(1:numVertices, final_mu, 'b');
    scatter(1:numVertices, final_confidence, 'r');
    title(t);
    legend('prediction', 'confidence');
    xlabel('vertex #i');
end

%% Find output folder

graphFileName = experiment.fileName;
slashes = find(graphFileName == '\');
lastSlash = slashes(end);
outputFolder = graphFileName(1:lastSlash);

%% Show final margin & confidence

if (figuresToShow.marginAndConfidence) 
    margin = algorithmOutput.margin;
    labeledPositive = algorithmOutput.labeledPositive;
    labeledNegative = algorithmOutput.labeledNegative;

    numVertices = length( final_mu );

    t = [ 'Results (margin & confidence).' paramsString ];

    figure('name', t);
    hold on;
    scatter(1:numVertices, final_confidence, 'b');
    scatter(1:numVertices, margin, 'k');
    scatter(labeledPositive, final_confidence(labeledPositive), '+g');
    scatter(labeledPositive, margin(labeledPositive), '+g');
    scatter(labeledNegative, final_confidence(labeledNegative), '+r');
    scatter(labeledNegative, margin(labeledNegative), '+r');
    title(t);
    legend('confidence', 'margin');
    xlabel('vertex #i');    
    % filename = [ 'results labeled regularized/labeled_high_confidence.fig';
    filename = [ outputFolder 'labeled_high_confidence.fig'];
    saveas(gcf, filename);
end

%% Show accumulative loss sorted by confidence

if (figuresToShow.assumulativeLoss)
    sortedAccumulativeLoss = experiment.result.sortedAccumulativeLoss;
    sortedConfidence = experiment.result.sortedConfidence;

    t = [ 'Results (sorted by confidence).' paramsString ];
    numRows = 2;
    numCols = 1;
    figure('name', t);
    subplot(numRows,numCols,1);
    plot(sortedAccumulativeLoss,  'b');
    title( [paramsString ...
            '\newline accumulative loss sorted by final confidence' ]);
    subplot(numRows,numCols,2);
    plot(sortedConfidence,  'r');
    title('sorted final confidence');
end

end

