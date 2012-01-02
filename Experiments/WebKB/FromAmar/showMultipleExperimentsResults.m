function showMultipleExperimentsResults...
    ( experiment, figuresToShow, experimentID )
%SHOWRESULTS Summary of this function goes here
%   Detailed explanation goes here

%%
multipleRuns = experiment.result;
algorithmParams     = experiment.params.algorithmParams;
constructionParams  = experiment.params.constructionParams;

%% extract parameters

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

%% Show accumulative loss sorted by confidence

if (figuresToShow.assumulativeLoss)
    sorted.by_confidence = multipleRuns.sorted_by_confidence();

    t = [ 'Results (sorted by confidence).' paramsString ];
    numRows = 2;
    numCols = 1;
    figure('name', t);
    subplot(numRows,numCols,1);
    plot(sorted.by_confidence.accumulative,  'b');
    title( [paramsString ...
            '\newline accumulative loss sorted by final confidence' ]);
    subplot(numRows,numCols,2);
    plot(sorted.by_confidence.confidence,  'r');
    title('sorted final confidence');
end

end

