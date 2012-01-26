classdef showSingleRunResults < handle

methods (Static)
    function show...
        ( experiment, experimentID, run_i, ...
          outputProperties)
    %SHOWSINGLERUNRESULTS Summary of this function goes here
    %   Detailed explanation goes here

        %% Extract single run output

        runOutput = experiment.getRun(run_i); % should get a SingleRun class instance

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
        maxIterations       = algorithmParams.numIterations;

        %% Show final prediction & confidence
        if (outputProperties.showSingleRuns == 0) 
            return;
        end

        %% create general params string
        generalParams = ...
            [' K = '                    num2str(K) ...
             ' makeSymetric = '         num2str(makeSymetric) ...
             ' numLabeledPerClass = '   num2str(numLabeledPerClass) ...
             ' exp ID = '               num2str(experimentID) ...
             ' run index = '            num2str(run_i)];
        


        %% extract info for CSSLMC results figure

        %CSSLMC_confidence    = runOutput.unlabeled_confidence(runOutput.CSSLMC);
        %CSSLMC_margin        = runOutput.unlabeled_margin(runOutput.CSSLMC);
        correctLabels        = runOutput.unlabeled_correct_labels();

        %% plot CSSLMC result figure

        %sortedCSSLMC.by_confidence = runOutput.sorted_by_confidence(runOutput.CSSLMC);
%         showSingleRunResults.plotBinaryCSSLResults...
%             (   CSSLMC_prediction, CSSLMC_confidence, ...
%             	CSSLMC_margin, correctLabels, sortedCSSLMC, outputProperties, ...
%                 [generalParams '\newline' paramsStringCSSLMC], ...
%                 'CSSLMC', experimentID, run_i);
%             
        %% extract info for CSSLMCF results figure
            
        %CSSLMCF_confidence    = runOutput.unlabeled_confidence(runOutput.CSSLMCF);
        %CSSLMCF_margin        = runOutput.unlabeled_margin(runOutput.CSSLMCF);
        
        %% plot CSSLMCF result figure
            
        %sortedCSSLMCF.by_confidence = runOutput.sorted_by_confidence(runOutput.CSSLMCF);
%         showSingleRunResults.plotBinaryCSSLResults...
%             (   CSSLMCF_prediction, CSSLMCF_confidence, ...
%             	CSSLMCF_margin, correctLabels, sortedCSSLMCF, outputProperties, ...
%                 [generalParams '\newline' paramsStringCSSLMCF],...
%                 'CSSLMCF', experimentID, run_i);
%                                
        %% extract info for results comparison figure

        %LP_prediction       = runOutput.unlabeled_prediction(runOutput.LP);
        
        %mistakes.CSSL       = runOutput.unlabeled_num_mistakes_CSSL();
        %mistakes.LP         = runOutput.unlabeled_num_mistakes(runOutput.LP);

        %% plot LP vs CSSLMC vs MAD
        
        generalAlgorithmParamsString = ...
                [' labeledConfidence = '    num2str(labeledConfidence) ...
                 ' alpha = '                num2str(alpha) ...
                 ' beta = '                 num2str(beta) ...
                 ' maxIterations = '        num2str(maxIterations) ];
        firstAlgorithmTitlePrefix = ['\newline' generalParams '\newline'];

        t = [ 'Algorithms Compare.' generalParams '. ' generalAlgorithmParamsString ];

        numRows = runOutput.isResultsAvailable( SingleRun.CSSLMC ) + ...
                  runOutput.isResultsAvailable( SingleRun.CSSLMCF ) + ...
                  runOutput.isResultsAvailable( SingleRun.MAD );
        numCols = 1;

        figure('name', t);

        %% plot algorithms output
        
        current = 1;
        if ( runOutput.isResultsAvailable( SingleRun.CSSLMC ) )
            %% create params string for CSSLMC

            numIterations       = runOutput.numIterations( SingleRun.CSSLMC);
            paramsStringCSSLMC = ...
                [' labeledConfidence = '    num2str(labeledConfidence) ...
                 ' alpha = '                num2str(alpha) ...
                 ' beta = '                 num2str(beta) ...
                 ' numIterations = '        num2str(numIterations) ];
             
             %% get CSSLMC prediction an plot it.
         
            mistakes_CSSLMC     = runOutput.unlabeled_num_mistakes(runOutput.CSSLMC);

            CSSLMC_prediction = runOutput.unlabeled_prediction(runOutput.CSSLMC);
            current = showSingleRunResults.plotPrediction...
                (numRows, numCols, current, CSSLMC_prediction, ...
                 correctLabels, mistakes_CSSLMC, 'CSSLMC', ...
                 [firstAlgorithmTitlePrefix paramsStringCSSLMC]);
             firstAlgorithmTitlePrefix = [];
        end

        if ( runOutput.isResultsAvailable( SingleRun.CSSLMCF ) )
            %% create params string for CSSLMCF

            numIterations       = runOutput.numIterations( SingleRun.CSSLMCF );
            
            paramsStringCSSLMCF = ...
                [' labeledConfidence = '    num2str(labeledConfidence) ...
                 ' alpha = '                num2str(alpha) ...
                 ' beta = '                 num2str(beta) ...
                 ' numIterations = '        num2str(numIterations) ];
             
             %% get CSSLMCF prediction an plot it.
             
             mistakes_CSSLMCF    = runOutput.unlabeled_num_mistakes(runOutput.CSSLMCF);

            CSSLMCF_prediction    = runOutput.unlabeled_prediction(runOutput.CSSLMCF);
            current = showSingleRunResults.plotPrediction...
                (numRows, numCols, current, CSSLMCF_prediction, ...
                 correctLabels, mistakes_CSSLMCF, 'CSSLMCF', ...
                 [firstAlgorithmTitlePrefix paramsStringCSSLMCF]);
             firstAlgorithmTitlePrefix=[];
        end

        if ( runOutput.isResultsAvailable( SingleRun.MAD ) )
            %% get MAD prediction an plot it.
            
            mistakes_MAD        = runOutput.unlabeled_num_mistakes(runOutput.MAD);
            MAD_prediction      = runOutput.unlabeled_prediction(runOutput.MAD);
            
            madParamsString = [' useGraphHeuristice = ' num2str(useGraphHeuristics)];

            current = showSingleRunResults.plotPrediction...
                (numRows, numCols, current, MAD_prediction, ...
                 correctLabels, mistakes_MAD, 'MAD', ...
                 [firstAlgorithmTitlePrefix madParamsString]); %#ok<NASGU>
             firstAlgorithmTitlePrefix = []; %#ok<NASGU>             
        end

        outputFolder = outputProperties.resultDir;
        folderName    = outputProperties.folderName;
        filename = [ outputFolder folderName '\singleResults.' ...
                      num2str(experimentID) '.' num2str(run_i) '.LP_vs_CSSL_vs_MAD.fig'];
        saveas(gcf, filename);
        close(gcf);
        
        %% plot precision and recall
        
        if ( runOutput.isResultsAvailable( SingleRun.MAD ) )
            outputProperties.experimentID   = experimentID;
            outputProperties.run_i          = run_i;
            showSingleRunResults.plotPrecisionAndRecall...
                 (  runOutput.unlabeled_scoreMatrix_testSet(SingleRun.MAD), ...
                    runOutput.testSetCorrectLabels(), outputProperties);
        end
        
        %% plot MAD probabilities figures
        
        filePrefix = [ outputFolder folderName '\singleResults.' ...
                      num2str(experimentID) '.' num2str(run_i)];
        
        MAD_result = runOutput.getAlgorithmResults(SingleRun.MAD);
        showSingleRunResults.plotProbabilities( MAD_result.probabilities(), filePrefix );

    end
        
    function current = plotPrediction...
            (numRows, numCols, current, ...
             prediction, correctLabels, numMistakes, ...
             algorithmName, paramsString)
        subplot(numRows, numCols, current);
        hold on;
        scatter(1:length(prediction), prediction, 'b');
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
    
    function plotPrecisionAndRecall(scoreMatrix, correctLabels, outputProperties)
        numLabels       = SSLMC_Result.calcNumLabels(scoreMatrix);
        for labelIndex = 1:numLabels
            outputProperties.class_i = labelIndex;
            scoreForLabel   = scoreMatrix(:,labelIndex);
            isCurrentLabel = (correctLabels == labelIndex);
            prebp = Evaluation.calcPRBEP(scoreForLabel, isCurrentLabel, outputProperties );
            disp(['prbep for class ' num2str(labelIndex) ' = ' num2str(prebp)]);
        end
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
                                   CSSL_margin, correctLabels, sorted, outputProperties, ...
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

        outputFolder = outputProperties.resultDir;
        folderName    = outputProperties.folderName;
        filename = [ outputFolder folderName '\singleResults.' ...
                     algorithmName '.' num2str(experimentID) '.' ...
                     num2str(run_i) '.fig'];
        saveas(gcf, filename);
        close(gcf);
    end

end % methods (Static)
    
end % classdef