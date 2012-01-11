function showSingleRunResults...
    ( experiment, experimentID, run_i, ...
      figuresToShow)
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
makeSymetric        = algorithmParams.makeSymetric;

%% create prams string

paramsString = ...
    [' labeledConfidence = ' num2str(labeledConfidence) ...
     ' alpha = '     num2str(alpha) ...
     ' beta = '      num2str(beta) ...
     ' K = '         num2str(K) ...
     ' makeSymetric = ' num2str(makeSymetric) ...
     ' exp ID = '    num2str(experimentID) ...
     ' run index = ' num2str(run_i)];

%% Show final prediction & confidence
if (figuresToShow.singleRuns == 0) 
    return;
end

%% extract info for CSSL results figure

CSSLMC_prediction    = runOutput.unlabeled_binary_prediction(runOutput.CSSLMC);
CSSLMC_confidence    = runOutput.unlabeled_confidence(runOutput.CSSLMC);
CSSLMC_margin        = runOutput.unlabeled_margin(runOutput.CSSLMC);
correctLabels        = runOutput.unlabeled_correct_labels();
numUnlabeledVertices = runOutput.numUnlabeledVertices();

%% plot CSSL result figure

t = [ 'unlabeled (prediction & confidence & margin).' paramsString ];

numRows = 3;
numCols = 2;

figure('name', t);

current = 1;
subplot(numRows, numCols, current);
hold on;
scatter(1:numUnlabeledVertices, CSSLMC_prediction, 'b');
plot( correctLabels, 'r' );
hold off;
title( ['unlabeled prediction (mu).\newline' paramsString] );
legend('prediction','correct');
xlabel('vertex #i');
ylabel('prediction (mu)');
current = current + numCols;

subplot(numRows, numCols, current);
scatter(1:numUnlabeledVertices, CSSLMC_confidence, 'r');
title( 'unlabeled confidence (v).' );
xlabel('vertex #i');
ylabel('confidence (v)');
current = current + numCols;

subplot(numRows, numCols, current);
scatter(1:numUnlabeledVertices, CSSLMC_margin, 'g');
title( 'unlabeled margin (mu*y).' );
xlabel('vertex #i');
ylabel('margin (mu*y)');

current = 2;

sorted.by_confidence = runOutput.sorted_by_confidence(runOutput.CSSLMC);

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
scatter(1:numUnlabeledVertices, sorted.by_confidence.margin, 'g');
title( 'margin (sorted by confidence)' );
xlabel('vertex #i');
ylabel('margin (mu*y)');

outputFolder = figuresToShow.resultDir;
groupName    = figuresToShow.groupName;
filename = [ outputFolder groupName '\singleResults.' ...
             num2str(experimentID) '.' num2str(run_i) '.fig'];
saveas(gcf, filename);
close(gcf);

%% extract info for CSSL results figure

LP_prediction       = runOutput.unlabeled_binary_prediction(runOutput.LP);
MAD_prediction      = runOutput.unlabeled_binary_prediction(runOutput.MAD);
%mistakes.CSSL       = runOutput.unlabeled_num_mistakes_CSSL();
mistakes.LP         = runOutput.unlabeled_num_mistakes(runOutput.LP);
mistakes.MAD        = runOutput.unlabeled_num_mistakes(runOutput.MAD);
mistakes.CSSLMC     = runOutput.unlabeled_num_mistakes(runOutput.CSSLMC);

%% plot LP vs CSSLMC vs MAD

t = [ 'LP vs CSSLMC vs MAD.' paramsString ];

numRows = 3;
numCols = 1;

figure('name', t);

current = 1;
subplot(numRows, numCols, current);
hold on;
scatter(1:numUnlabeledVertices, CSSLMC_prediction, 'b');
plot( correctLabels, 'r' );
hold off;
title( ['unlabeled prediction (mu) ' ...
        '(#mistakes = ' num2str(mistakes.CSSLMC) ')' ...
        '\newline' paramsString] );
legend('prediction','correct');
xlabel('vertex #i');
ylabel('prediction (mu)');
current = current + numCols;

subplot(numRows, numCols, current);
hold on;
scatter(1:numUnlabeledVertices, LP_prediction, 'b');
plot( correctLabels, 'r' );
hold off;
legend('prediction','correct');
title( ['LP prediction (#mistakes = ' num2str(mistakes.LP) ')']  );
xlabel('vertex #i');
ylabel('y');
current = current + numCols;

subplot(numRows, numCols, current);
hold on;
scatter(1:numUnlabeledVertices, MAD_prediction, 'b');
plot( correctLabels, 'r' );
hold off;
legend('prediction','correct');
title( ['MAD prediction (#mistakes = ' num2str(mistakes.MAD) ')']  );
xlabel('vertex #i');
ylabel('y');
current = current + numCols;

outputFolder = figuresToShow.resultDir;
groupName    = figuresToShow.groupName;
filename = [ outputFolder groupName '\singleResults.' ...
              num2str(experimentID) '.' num2str(run_i) '.LP_vs_CSSL_vs_MAD.fig'];
saveas(gcf, filename);
close(gcf);

end
