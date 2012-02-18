classdef MultipleRunsResult < handle

properties
    m_algorithmResults;
    m_numClasses;
end
    
methods
    %% create
    
    function create( this, multipleRuns )
        this.createAveragePRBEP(multipleRuns);
        this.createAverageAccuracy_testSet(multipleRuns);
    end
    
    %% createAveragePRBEP
    
    function createAveragePRBEP( this, multipleRuns )
        for algorithm_i=multipleRuns.availableResultsAlgorithmRange()
            algorithmName = AlgorithmTypeToStringConverter.convert( algorithm_i );
            disp(['algorithmName =  ' algorithmName]);
            [averagePRBEP estimatedAveragePRBEP] = ...
                multipleRuns.calcAveragePrecisionAndRecall(algorithm_i);
            numClasses = numel(averagePRBEP);
            disp('averagePRBEP');
            disp(averagePRBEP);
            disp('estimatedAveragePRBEP');
            disp(estimatedAveragePRBEP);
            this.m_algorithmResults{algorithm_i}.averagePRBEP = averagePRBEP;
            this.m_algorithmResults{algorithm_i}.estimatedAveragePRBEP = estimatedAveragePRBEP;
        end
        this.m_numClasses = numClasses;
    end
    
    %% createAverageAccuracy_testSet
    
    function createAverageAccuracy_testSet( this, multipleRuns )
        for algorithm_i=multipleRuns.availableResultsAlgorithmRange()
            avgAccuracy = multipleRuns.calcAverageAccuracy_testSet(algorithm_i);
            algorithmName = AlgorithmTypeToStringConverter.convert( algorithm_i );
            disp(['Algorithm ' algorithmName ...
                  ' average accuracy = ' num2str(avgAccuracy)]);
            this.m_algorithmResults{algorithm_i}.avgAccuracy_testSet = avgAccuracy;
        end
    end
    
    %% resultsTablePRBEP
    
    function R = resultsTablePRBEP( this, isEstimated )
        algorithmsInResult = MultipleRunsResult.algorithmsResultOrder();
        numAlgorithms = length(algorithmsInResult);
        numClasses = this.m_numClasses;
        R = zeros(numClasses, numAlgorithms);
        table_i = 1;
        for algorithm_i=algorithmsInResult
            if algorithm_i <= length(this.m_algorithmResults) && ...
               ~isempty(this.m_algorithmResults{algorithm_i})
                result = this.m_algorithmResults{algorithm_i};
                if isEstimated
                    algorithmStats = result.estimatedAveragePRBEP;
                else
                    algorithmStats = result.averagePRBEP;
                end 
            else
                algorithmStats = zeros(numClasses, 1);
            end
            R(:,table_i) = algorithmStats;
            table_i = table_i + 1;
        end
    end
    
    %% avgAccuracy_testSet
    
    function R = avgAccuracy_testSet(this)
        algorithmsInResult = MultipleRunsResult.algorithmsResultOrder();
        numAlgorithms = length(algorithmsInResult);
        R = zeros(1, numAlgorithms);
        table_i = 1;
        for algorithm_i=algorithmsInResult
            if algorithm_i <= length(this.m_algorithmResults) && ...
               ~isempty(this.m_algorithmResults{algorithm_i})
                result = this.m_algorithmResults{algorithm_i};
                avgAccuracy = result.avgAccuracy_testSet;
            else
                avgAccuracy = 0;
            end
            R(table_i) = avgAccuracy;
            table_i = table_i + 1;
        end
    end
    
    %% numClasses
    
    function R = numClasses(this)
        R = this.m_numClasses;
    end

end % methods

methods (Static)
    function R = algorithmsResultOrder()
        R = [SingleRun.CSSLMC   ...
             SingleRun.CSSLMCF  ...
             SingleRun.MAD];
    end
end

end % classdef