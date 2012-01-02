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
if (figuresToShow.predictionAndConfidence) 
    final_mu            = runOutput.unlabeled_final_mu();
    final_confidence    = runOutput.unlabeled_final_confidence();
    margin              = runOutput.unlabeled_margin();
    numVertices = length( final_mu);

    t = [ 'unlabeled (prediction & confidence & margin).' paramsString ];

    numRows = 3;
    numCols = 1;
    
    figure('name', t);
    
    subplot(numRows, numCols, 1);
    scatter(1:numVertices, final_mu, 'b');
    title( ['unlabeled prediction (mu).' paramsString] );
    xlabel('vertex #i');
    ylabel('prediction (mu)');
    
    subplot(numRows, numCols, 2);
    scatter(1:numVertices, final_confidence, 'r');
    title( ['unlabeled confidence (v).' paramsString] );
    xlabel('vertex #i');
    ylabel('confidence (v)');
    
 	subplot(numRows, numCols, 3);
    scatter(1:numVertices, margin, 'r');
    title( ['unlabeled margin (mu*y).' paramsString] );
    xlabel('vertex #i');
    ylabel('margin (mu*y)');
    
    filename = [ outputFolder t '.' num2str(run_i) '.fig'];
    saveas(gcf, filename);
    
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

