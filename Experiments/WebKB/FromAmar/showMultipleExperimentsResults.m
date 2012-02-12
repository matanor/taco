classdef showMultipleExperimentsResults < handle

methods (Static)
    
    %% show
    
    function show( multipleRuns, outputManager )

        showMultipleExperimentsResults.showAveragePrecisionAndRecall(multipleRuns);
        showMultipleExperimentsResults.printAverageAccuracy_testSet(multipleRuns);
         
        % Show accumulative loss sorted by confidence

        if (outputManager.m_showAccumulativeLoss)
            sorted.by_confidence = multipleRuns.sorted_by_confidence(SingleRun.CSSLMC);

            t = [ 'Results (sorted by confidence) CSSLMC.' paramsString ];
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
    
    %% showAveragePrecisionAndRecall
    
    function showAveragePrecisionAndRecall( multipleRuns )
        for algorithm_i=multipleRuns.availableResultsAlgorithmRange()
            algorithmName = AlgorithmTypeToStringConverter.convert( algorithm_i );
            disp(['algorithmName =  ' algorithmName]);
            [averagePrbep estimatedAveragePRBEP] = ...
                multipleRuns.calcAveragePrecisionAndRecall(algorithm_i);
            disp('averagePrbep');
            disp(averagePrbep);
            disp('estimatedAveragePRBEP');
            disp(estimatedAveragePRBEP);
        end
    end
    
    %% printAverageAccuracy_testSet
    
    function printAverageAccuracy_testSet( multipleRuns )
        for algorithm_i=multipleRuns.availableResultsAlgorithmRange()
            avgAccuracy = multipleRuns.calcAverageAccuracy_testSet(algorithm_i);
            algorithmName = AlgorithmTypeToStringConverter.convert( algorithm_i );
            disp(['Algorithm ' algorithmName ...
                  ' average accuracy = ' num2str(avgAccuracy)]);
        end
    end

end % methods (Static)

end % classdef