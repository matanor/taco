function showSingleRunResults...
    ( experiment, experimentID, run_i, figuresToShow)
%SHOWSINGLERUNRESULTS Summary of this function goes here
%   Detailed explanation goes here

%% Extract single run output

runOutput = experiment.result.getRun(run_i);

%% extract parameters
algorithmParams     = experiment.params.algorithmParams;
constructionParams  = experiment.params.constructionParams;

labeledConfidence   = algorithmParams.labeledConfidence;
alpha               = algorithmParams.alpha;
beta                = algorithmParams.beta;
K                   = constructionParams.K;

%% create prams string

paramsString = ...
    [' labeledConfidence = ' num2str(labeledConfidence) ...
     ' alpha = '     num2str(alpha) ...
     ' beta = '      num2str(beta) ...
     ' K = '         num2str(K) ...
     ' exp ID = '    num2str(experimentID) ...
     ' run index = ' num2str(run_i)];

%% Find output folder

graphFileName = experiment.fileName;
slashes = find(graphFileName == '\');
lastSlash = slashes(end);
outputFolder = graphFileName(1:lastSlash);

%% Show final prediction & confidence
if (figuresToShow.singleRuns) 
    final_mu            = runOutput.unlabeled_final_mu();
    final_confidence    = runOutput.unlabeled_final_confidence();
    margin              = runOutput.unlabeled_margin();
    numVertices = length( final_mu);

    t = [ 'unlabeled (prediction & confidence & margin).' paramsString ];

    numRows = 3;
    numCols = 2;
    
    figure('name', t);
    
    current = 1;
    subplot(numRows, numCols, current);
    scatter(1:numVertices, final_mu, 'b');
    title( ['unlabeled prediction (mu).\newline' paramsString] );
    xlabel('vertex #i');
    ylabel('prediction (mu)');
    current = current + numCols;
    
    subplot(numRows, numCols, current);
    scatter(1:numVertices, final_confidence, 'r');
    title( 'unlabeled confidence (v).' );
    xlabel('vertex #i');
    ylabel('confidence (v)');
    current = current + numCols;
    
 	subplot(numRows, numCols, current);
    scatter(1:numVertices, margin, 'g');
    title( 'unlabeled margin (mu*y).' );
    xlabel('vertex #i');
    ylabel('margin (mu*y)');
    
    current = 2;
    
    sorted.by_confidence = runOutput.sorted_by_confidence();
    
    subplot(numRows, numCols, current);
    plot(sorted.by_confidence.accumulative, 'r');
    title( 'accumulative (sorted by confidence)' );
    xlabel('vertex #i');
    ylabel('# mistakes');
    current = current + numCols;

    subplot(numRows, numCols, current);
    plot(sorted.by_confidence.confidence, 'b');
    title( 'confidence (sorted)' );
    xlabel('vertex #i');
    ylabel('confidence (v)');
    current = current + numCols;

    subplot(numRows, numCols, current);
    scatter(1:numVertices, sorted.by_confidence.margin, 'g');
    title( 'margin (sorted by confidence)' );
    xlabel('vertex #i');
    ylabel('margin (mu*y)');
    
    filename = [ outputFolder 'singleResults.' ...
                 num2str(experimentID) '.' num2str(run_i) '.fig'];
    saveas(gcf, filename);
    close(gcf);
    
end

% 
% %% Show final margin & confidence
% 
% if (figuresToShow.marginAndConfidence) 
%     margin = runOutput.unlabeled_margin();
% %     labeledPositive = runOutput.labeledPositive;
% %     labeledNegative = runOutput.labeledNegative;
% 
%     numVertices = length( final_mu );
% 
%     t = [ 'unlabeled (margin & confidence).' paramsString ];
% 
%     figure('name', t);
%     hold on;
%     scatter(1:numVertices, final_confidence, 'b');
%     scatter(1:numVertices, margin, 'k');
% %     scatter(labeledPositive, final_confidence(labeledPositive), '+g');
% %     scatter(labeledPositive, margin(labeledPositive), '+g');
% %     scatter(labeledNegative, final_confidence(labeledNegative), '+r');
% %     scatter(labeledNegative, margin(labeledNegative), '+r');
%     title(t);
%     legend('confidence', 'margin');
%     xlabel('vertex #i');    
%     filename = [ outputFolder t '.fig'];
%     saveas(gcf, filename);
% end

 
end

