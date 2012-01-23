classdef showSingleRunResults < handle

methods (Static)
    function show...
        ( experiment, experimentID, run_i, ...
          figuresToShow)
    %SHOWSINGLERUNRESULTS Summary of this function goes here
    %   Detailed explanation goes here

        %% Extract single run output

        runOutput = experiment.getRun(run_i);

        %% extract parameters
        algorithmParams     = experiment.algorithmParams();
        constructionParams  = experiment.constructionParams();

        labeledConfidence   = algorithmParams.labeledConfidence;
        alpha               = algorithmParams.alpha;
        beta                = algorithmParams.beta;
        K                   = constructionParams.K;
        numLabeledPerClass  = constructionParams.numLabeled;
        makeSymetric        = algorithmParams.makeSymetric;
        useGraphHeuristics  = algorithmParams.useGraphHeuristics;

        %% Show final prediction & confidence
        if (figuresToShow.singleRuns == 0) 
            return;
        end

        %% create general params string
        generalParams = ...
            [' K = '                    num2str(K) ...
             ' makeSymetric = '         num2str(makeSymetric) ...
             ' numLabeledPerClass = '   num2str(numLabeledPerClass) ...
             ' exp ID = '               num2str(experimentID) ...
             ' run index = '            num2str(run_i)];
        
        %% create params string for CSSLMC

        numIterations       = runOutput.numIterations( SingleRun.CSSLMC);
        paramsStringCSSLMC = ...
            [' labeledConfidence = '    num2str(labeledConfidence) ...
             ' alpha = '                num2str(alpha) ...
             ' beta = '                 num2str(beta) ...
             ' numIterations = '        num2str(numIterations) ];

        %% extract info for CSSLMC results figure

        CSSLMC_prediction    = runOutput.unlabeled_binary_prediction(runOutput.CSSLMC);
        CSSLMC_confidence    = runOutput.unlabeled_confidence(runOutput.CSSLMC);
        CSSLMC_margin        = runOutput.unlabeled_margin(runOutput.CSSLMC);
        correctLabels        = runOutput.unlabeled_correct_labels();

        %% plot CSSLMC result figure

        sortedCSSLMC.by_confidence = runOutput.sorted_by_confidence(runOutput.CSSLMC);
        showSingleRunResults.plotBinaryCSSLResults...
            (   CSSLMC_prediction, CSSLMC_confidence, ...
            	CSSLMC_margin, correctLabels, sortedCSSLMC, figuresToShow, ...
                [generalParams '\newline' paramsStringCSSLMC], ...
                'CSSLMC', experimentID, run_i);
            
        %% extract info for CSSLMCF results figure
            
        CSSLMCF_prediction    = runOutput.unlabeled_binary_prediction(runOutput.CSSLMCF);
        CSSLMCF_confidence    = runOutput.unlabeled_confidence(runOutput.CSSLMCF);
        CSSLMCF_margin        = runOutput.unlabeled_margin(runOutput.CSSLMCF);
        
        %% create params string for CSSLMCF

        numIterations       = runOutput.numIterations( SingleRun.CSSLMCF);
        
        paramsStringCSSLMCF = ...
            [' labeledConfidence = '    num2str(labeledConfidence) ...
             ' alpha = '                num2str(alpha) ...
             ' beta = '                 num2str(beta) ...
             ' numIterations = '        num2str(numIterations) ];
        
        %% plot CSSLMCF result figure
            
        sortedCSSLMCF.by_confidence = runOutput.sorted_by_confidence(runOutput.CSSLMCF);
        showSingleRunResults.plotBinaryCSSLResults...
            (   CSSLMCF_prediction, CSSLMCF_confidence, ...
            	CSSLMCF_margin, correctLabels, sortedCSSLMCF, figuresToShow, ...
                [generalParams '\newline' paramsStringCSSLMCF],...
                'CSSLMCF', experimentID, run_i);
                               
        %% extract info for results comparison figure

        LP_prediction       = runOutput.unlabeled_binary_prediction(runOutput.LP);
        MAD_prediction      = runOutput.unlabeled_binary_prediction(runOutput.MAD);
        CSSLMCF_prediction  = runOutput.unlabeled_binary_prediction(runOutput.CSSLMCF);
        %mistakes.CSSL       = runOutput.unlabeled_num_mistakes_CSSL();
        mistakes.LP         = runOutput.unlabeled_num_mistakes(runOutput.LP);
        mistakes.MAD        = runOutput.unlabeled_num_mistakes(runOutput.MAD);
        mistakes.CSSLMC     = runOutput.unlabeled_num_mistakes(runOutput.CSSLMC);
        mistakes.CSSLMCF    = runOutput.unlabeled_num_mistakes(runOutput.CSSLMCF);

        %% plot LP vs CSSLMC vs MAD

        t = [ 'LP vs CSSLMC vs MAD.' generalParams '. ' paramsStringCSSLMCF ];

        numRows = 4;
        numCols = 1;

        figure('name', t);

        current = 1;
        current = showSingleRunResults.plotBinaryPrediction...
            (numRows, numCols, current, CSSLMC_prediction, ...
             correctLabels, mistakes.CSSLMC, 'CSSLMC', ...
             ['\newline' generalParams '\newline' paramsStringCSSLMC]);

        current = showSingleRunResults.plotBinaryPrediction...
            (numRows, numCols, current, CSSLMCF_prediction, ...
             correctLabels, mistakes.CSSLMCF, 'CSSLMCF', paramsStringCSSLMCF);

        current = showSingleRunResults.plotBinaryPrediction...
            (numRows, numCols, current, LP_prediction, ...
             correctLabels, mistakes.LP, 'LP', '');

        madParamsString = [' useGraphHeuristice = ' num2str(useGraphHeuristics)];
        
        current = showSingleRunResults.plotBinaryPrediction...
            (numRows, numCols, current, MAD_prediction, ...
             correctLabels, mistakes.MAD, 'MAD', madParamsString);

        outputFolder = figuresToShow.resultDir;
        groupName    = figuresToShow.groupName;
        filename = [ outputFolder groupName '\singleResults.' ...
                      num2str(experimentID) '.' num2str(run_i) '.LP_vs_CSSL_vs_MAD.fig'];
        saveas(gcf, filename);
        close(gcf);
        
        %% plot MAD probabilities figure
        
        filePrefix = [ outputFolder groupName '\singleResults.' ...
                      num2str(experimentID) '.' num2str(run_i)];
        
        MAD_result = runOutput.getAlgorithmResults(SingleRun.MAD);
        showSingleRunResults.plotProbabilities( MAD_result.probabilities(), filePrefix );

    end
    
    function current = plotBinaryPrediction...
            (numRows, numCols, current, ...
             binaryPrediction, correctLabels, numMistakes, ...
             algorithmName, paramsString)
        subplot(numRows, numCols, current);
        hold on;
        scatter(1:length(binaryPrediction), binaryPrediction, 'b');
        plot( correctLabels, 'r' );
        hold off;
        legend('prediction','correct');
        title( [algorithmName ...
               ' prediction (#mistakes = ' num2str(numMistakes) ')' ...
               paramsString ]  );
        xlabel('vertex #i');
        ylabel('y');
        current = current + numCols;
    end
    
    function plotProbabilities(p, filePrefix)
        showSingleRunResults.scatterFigure('p_inject'    , p.inject, filePrefix);
        showSingleRunResults.scatterFigure('p_continue'  , p.continue, filePrefix);
        showSingleRunResults.scatterFigure('p_abandon'   , p.abandon, filePrefix);
    end
    
    function scatterFigure(t, x, filePrefix)
        figure('name',t);
        title(t)
        scatter(1:length(x),x);  
        filename = [filePrefix '.' t '.fig'];
        saveas(gcf, filename);
        close(gcf);
    end
    
    function plotBinaryCSSLResults(CSSL_prediction, CSSL_confidence, ...
                                   CSSL_margin, correctLabels, sorted, figuresToShow, ...
                                   paramsString, algorithmName, experimentID, run_i)

        t = [ 'unlabeled (prediction & confidence & margin). ' algorithmName '. '  paramsString ];

        numRows = 3;
        numCols = 2;
        numUnlabeledVertices = length(CSSL_prediction);

        figure('name', t);

        current = 1;
        subplot(numRows, numCols, current);
        hold on;
        scatter(1:numUnlabeledVertices, CSSL_prediction, 'b');
        plot( correctLabels, 'r' );
        hold off;
        title( ['unlabeled prediction (mu).\newline' paramsString] );
        legend('prediction','correct');
        xlabel('vertex #i');
        ylabel('prediction (mu)');
        current = current + numCols;

        subplot(numRows, numCols, current);
        scatter(1:numUnlabeledVertices, CSSL_confidence, 'r');
        title( 'unlabeled confidence (v).' );
        xlabel('vertex #i');
        ylabel('confidence (v)');
        current = current + numCols;

        subplot(numRows, numCols, current);
        scatter(1:numUnlabeledVertices, CSSL_margin, 'g');
        title( 'unlabeled margin (mu*y).' );
        xlabel('vertex #i');
        ylabel('margin (mu*y)');

        current = 2;

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
                     algorithmName '.' num2str(experimentID) '.' ...
                     num2str(run_i) '.fig'];
        saveas(gcf, filename);
        close(gcf);
    end

end % methods (Static)
    
end % classdef