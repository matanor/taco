classdef showSingleRunResults < handle

methods (Static)
    function show( singleRun, outputManager)
    %SHOWSINGLERUNRESULTS Summary of this function goes here
    %   Detailed explanation goes here

        % extract parameters
        constructionParams  = singleRun.constructionParams();

        %% Show final prediction & confidence
        if (outputManager.m_showSingleRuns == 0) 
            return;
        end

        % create general params string
        generalParams = ...
            [' K = '                    num2str(constructionParams.K) ...
             ' numLabeled = '           num2str(constructionParams.numLabeled) ];
%              ' numLabeledPerClass = '   num2str(constructionParams.numLabeledPerClass) ];
             
        % algorithm comparison

        t = [ 'Algorithms Compare.' outputManager.m_description ' ' generalParams];

        numRows = singleRun.isResultsAvailable( SingleRun.CSSLMC ) + ...
                  singleRun.isResultsAvailable( SingleRun.CSSLMCF ) + ...
                  singleRun.isResultsAvailable( SingleRun.MAD );
        numCols = 1;

        figure('name', t);

        % plot all algorithms output

        correctLabels = singleRun.unlabeled_correct_labels();
        current = 1;
        
        for algorithm_i = singleRun.availableResultsAlgorithmRange()
            current = showSingleRunResults.plotPrediction...
                (singleRun, numRows, numCols, current, correctLabels, algorithm_i );
        end
        
        filename = outputManager.createFileNameAtCurrentFolder...
            (['singleResults.' outputManager.m_description '.AlgorithmCompare.fig']);
        saveas(gcf, filename);
        close(gcf);
        
        % plot precision and recall
        
        for algorithm_i = singleRun.availableResultsAlgorithmRange()
            showSingleRunResults.plotPrecisionAndRecall_allLabels...
                 (  singleRun, algorithm_i, outputManager);
        end
        
        % plot MAD probabilities figures
        
        if ( singleRun.isResultsAvailable( SingleRun.MAD ) )
            filePrefix = outputManager.createFileNameAtCurrentFolder...
                (['singleResults.' outputManager.m_description]);
        
            MAD_result = singleRun.getAlgorithmResults(SingleRun.MAD);
            showSingleRunResults.plotProbabilities( MAD_result.probabilities(), filePrefix );
        end

    end
    
    %% plotPrediction
    
    function current = plotPrediction...
            (singleRun, numRows, numCols, current, correctLabels, algorithmType)
        algorithmParams = singleRun.getParams( algorithmType );    
        paramsString    = Utilities.StructToStringConverter( algorithmParams );
         
        algorithmName = AlgorithmTypeToStringConverter.convert( algorithmType );
        numMistakes = singleRun.unlabeled_num_mistakes(algorithmType);
        prediction  = singleRun.unlabeled_prediction(algorithmType);

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
    
    %% plotPrecisionAndRecall_allLabels
    
    function plotPrecisionAndRecall_allLabels...
            (singleRun, algorithmType, outputManager)
        numLabels       = singleRun.numLabels();
        
        paramsString = Utilities.StructToStringConverter(singleRun.getParams(algorithmType));
        testSetSize         = singleRun.testSetSize();
        
        algorithmName = AlgorithmTypeToStringConverter.convert(algorithmType);
        disp([  'Algorithm = ' algorithmName...
                ' ' paramsString ...
                ' test set size = '         num2str(testSetSize)]);
            
        for labelIndex = 1:numLabels
            [prbep precision recall] = singleRun.calcPRBEP_testSet    (algorithmType, labelIndex);
            estimated_prbep          = singleRun.estimatePRBEP_testSet(algorithmType, labelIndex);
            showSingleRunResults.plotAndSave_PrecisionAndRecall...
                (precision, recall, labelIndex, algorithmName, outputManager);
            disp(['prbep (estimated) for class ' num2str(labelIndex) ' = ' num2str(prbep)...
                  ' (' num2str(estimated_prbep) ')']);
        end
    end % plotPrecisionAndRecall_allLabels
    
    %% plotAndSave_PrecisionAndRecall
    
    function plotAndSave_PrecisionAndRecall...
            ( precision, recall, class_i, algorithmName, outputManager )

        t = ['precision and recall ' ...
             ' class index  = ' num2str(class_i) ... 
             ' algorithm = '  algorithmName];
         
        h = showSingleRunResults.plotPrecisionAndRecall(precision, recall, t);

        filename = outputManager.createFileNameAtCurrentFolder...
            ( [ 'SingleResults.' outputManager.m_description '.' ...
                num2str(class_i) '.' algorithmName '.PrecisionRecall.fig']);
        saveas(h, filename); close(h);
    end
    
    %% plotPrecisionAndRecall
    
    function h = plotPrecisionAndRecall(precision, recall, t)
        h = figure('name',t);
        hold on;
        plot(precision, 'r');
        plot(recall,    'g');
        hold off;
        title(t);
        legend('precision','recall');
        xlabel('threshold #i');
        ylabel('precision/recall');
    end
    
    %% plotProbabilities
    
    function plotProbabilities(p, filePrefix)
        showSingleRunResults.scatterFigure('p_inject'    , p.inject, filePrefix);
        showSingleRunResults.scatterFigure('p_continue'  , p.continue, filePrefix);
        showSingleRunResults.scatterFigure('p_abandon'   , p.abandon, filePrefix);
    end
    
    %% scatterFigure
    
    function scatterFigure(t, x, filePrefix)
        figure('name',t);
        title(t)
        scatter(1:length(x),x);  
        filename = [filePrefix '.' t '.fig'];
        saveas(gcf, filename);
        close(gcf);
    end
    
    %% plotBinaryCSSLResults
    
    function plotBinaryCSSLResults(CSSL_prediction, CSSL_confidence, ...
                                   CSSL_margin, correctLabels, sorted, outputManager, ...
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

        filename = outputManager.createFileNameAtCurrentFolder...
            (['singleResults.' algorithmName '.' num2str(experimentID) '.' ...
              num2str(run_i) '.fig']);
        saveas(gcf, filename);
        close(gcf);
    end

end % methods (Static)
    
end % classdef