function showMultipleExperimentsResults...
    ( experiment, figuresToShow, experimentID )
%SHOWRESULTS Summary of this function goes here
%   Detailed explanation goes here

%%
multipleRuns        = experiment;
algorithmParams     = multipleRuns.algorithmParams();
constructionParams  = multipleRuns.constructionParams();

%% extract parameters

labeledConfidence   = algorithmParams.labeledConfidence;
alpha               = algorithmParams.alpha;
beta                = algorithmParams.beta;
K                   = constructionParams.K;
numLabeledPreClass  = constructionParams.numLabeled;
makeSymetric        = algorithmParams.makeSymetric;

paramsString = ...
    [' labeledConfidence = ' num2str(labeledConfidence) ...
     ' alpha = '    num2str(alpha) ...
     ' beta = '     num2str(beta) ...
     ' K = '        num2str(K) ...
     '\newline' ...
     ' makeSymetric = ' num2str(makeSymetric) ...
     ' numLabeledPreClass = ' num2str(numLabeledPreClass ) ...
     ' exp ID = '   num2str(experimentID)];

%% Show accumulative loss sorted by confidence

if (figuresToShow.accumulativeLoss)
    sorted.by_confidence = multipleRuns.sorted_by_confidence();

    t = [ 'Results (sorted by confidence).' paramsString ];
    numRows = 2;
    numCols = 1;
    figure('name', t);
    subplot(numRows,numCols,1);
    plot(sorted.by_confidence.accumulative,  'b');
    title( [paramsString ...
            '\newline accumulative loss sorted by final confidence' ]);
    ylabel('# mistakes');
        
    subplot(numRows,numCols,2);
    plot(log(sorted.by_confidence.confidence),  'r');
    title('sorted final confidence');
    ylabel('log(confidence)');
end

end

