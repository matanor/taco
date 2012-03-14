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
        this.createAverageMRR_testSet(multipleRuns);
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
    
    %% createAverageMRR_testSet
    
    function createAverageMRR_testSet(this, multipleRuns)
        for algorithm_i=multipleRuns.availableResultsAlgorithmRange()
            [meanMRR stddevMRR] = multipleRuns.calcAverageMRR( algorithm_i);
            algorithmName = AlgorithmTypeToStringConverter.convert( algorithm_i );
            disp(['Algorithm ' algorithmName ...
                  ' avg (stddev) MRR = ' num2str(meanMRR) ' (' num2str(stddevMRR) ')']);
            this.m_algorithmResults{algorithm_i}.MRR.mean   = meanMRR;
            this.m_algorithmResults{algorithm_i}.MRR.stddev = stddevMRR;
        end
    end
    
    %% avgPRBEP
    
    function R = avgPRBEP( this, algorithmType, isEstimated )
        algResult = this.m_algorithmResults{algorithmType};
        if isEstimated
            R = mean(algResult.estimatedAveragePRBEP);
        else
            R = mean(algResult.averagePRBEP);
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
            if this.hasAlgorithmResult(algorithm_i)
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
    
    %% hasAlgorithmResult
    
    function R = hasAlgorithmResult(this, algorithm_i)
        R = algorithm_i <= length(this.m_algorithmResults) && ...
               ~isempty(this.m_algorithmResults{algorithm_i});
    end
    
    %% avgMRR_testSet
    
    function [mean stddev] = avgMRR_testSet(this, algorithmType)
        mean = this.m_algorithmResults{algorithmType}.MRR.mean; 
        stddev = this.m_algorithmResults{algorithmType}.MRR.stddev; 
    end
    
    %% avgAccuracy_testSet_perAlgorithm
    
    function R = avgAccuracy_testSet_perAlgorithm(this, algorithmType)
        R = this.m_algorithmResults{algorithmType}.avgAccuracy_testSet;
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