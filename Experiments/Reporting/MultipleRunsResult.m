classdef MultipleRunsResult < handle

properties
    m_algorithmResults;
    m_numClasses;
end
    
methods
    %% create
    
    function create( this, multipleRuns )
        for algorithm_i=multipleRuns.availableResultsAlgorithmRange()
            this.createAveragePRBEP(multipleRuns, algorithm_i);
            this.createAverageAccuracy_testSet(multipleRuns, algorithm_i);
            this.createAverageMRR_testSet(multipleRuns, algorithm_i);
            this.createAverage_macroMRR_testSet(multipleRuns, algorithm_i);
        end
    end
    
    %% createAveragePRBEP
    
    function createAveragePRBEP( this, multipleRuns, algorithm_i )
        algorithmName = AlgorithmTypeToStringConverter.convert( algorithm_i );
        Logger.log(['algorithmName =  ' algorithmName]);
        [exactPRBEP_perLabel estimatedPRBEP_perLabel] = ...
            multipleRuns.calcAveragePrecisionAndRecall(algorithm_i);
        numClasses = numel(exactPRBEP_perLabel.mean);
        Logger.log('averagePRBEP');
        Logger.log(num2str(exactPRBEP_perLabel.mean.'));
        Logger.log('estimatedAveragePRBEP');
        Logger.log(num2str(estimatedPRBEP_perLabel.mean.'));
        this.m_algorithmResults{algorithm_i}.exactPRBEP_perLabel     = exactPRBEP_perLabel;
        this.m_algorithmResults{algorithm_i}.estimatedPRBEP_perLabel = estimatedPRBEP_perLabel;
        this.m_numClasses = numClasses;
    end
    
    %% createAverageAccuracy_testSet
    
    function createAverageAccuracy_testSet( this, multipleRuns, algorithm_i )
        [avgAccuracy stddevAccuracy] = ...
            multipleRuns.calcAverageAccuracy_testSet(algorithm_i);
        algorithmName = AlgorithmTypeToStringConverter.convert( algorithm_i );
        Logger.log(['Algorithm ' algorithmName ...
              ' avg (stddev) accuracy = ' ...
              num2str(avgAccuracy) ' (' num2str(stddevAccuracy) ')']);
        this.m_algorithmResults{algorithm_i}.accuracy.mean   = avgAccuracy;
        this.m_algorithmResults{algorithm_i}.accuracy.stddev = stddevAccuracy;
    end
    
    %% createAverageMRR_testSet
    
    function createAverageMRR_testSet(this, multipleRuns, algorithm_i)
        [meanMRR stddevMRR] = multipleRuns.calcAverageMRR( algorithm_i);
        algorithmName = AlgorithmTypeToStringConverter.convert( algorithm_i );
        Logger.log(['Algorithm ' algorithmName ...
              ' avg (stddev) MRR = ' num2str(meanMRR) ' (' num2str(stddevMRR) ')']);
        this.m_algorithmResults{algorithm_i}.MRR.mean   = meanMRR;
        this.m_algorithmResults{algorithm_i}.MRR.stddev = stddevMRR;
    end
    
    %% createAverage_macroMRR_testSet
    
    function createAverage_macroMRR_testSet(this, multipleRuns, algorithm_i )
        [mean stddev] = multipleRuns.calcAverage_macroMRR( algorithm_i);
        algorithmName = AlgorithmTypeToStringConverter.convert( algorithm_i );
        Logger.log(['Algorithm ' algorithmName ...
              ' avg (stddev) macro MRR = ' num2str(mean) ' (' num2str(stddev) ')']);
        this.m_algorithmResults{algorithm_i}.macroMRR.mean   = mean;
        this.m_algorithmResults{algorithm_i}.macroMRR.stddev = stddev;
    end
    
    %% avgPRBEP_allLabels
    
    function R = avgPRBEP_allLabels( this, algorithmType, isEstimated )
        algResult = this.m_algorithmResults{algorithmType};
        if isEstimated
            R.mean   = mean(    algResult.estimatedPRBEP_perLabel.mean);
            R.stddev = sqrt(var(algResult.estimatedPRBEP_perLabel.mean));
        else
            R.mean   = mean(    algResult.exactPRBEP_perLabel.mean);
            R.stddev = sqrt(var(algResult.exactPRBEP_perLabel.mean));
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
                    algorithmStats = result.estimatedPRBEP_perLabel.mean;
                else
                    algorithmStats = result.exactPRBEP_perLabel.mean;
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
        mean   = this.m_algorithmResults{algorithmType}.MRR.mean; 
        stddev = this.m_algorithmResults{algorithmType}.MRR.stddev; 
    end
    
    %% avg_macroMRR_testSet
    
    function [mean stddev] = avg_macroMRR_testSet(this, algorithmType)
        mean   = this.m_algorithmResults{algorithmType}.macroMRR.mean; 
        stddev = this.m_algorithmResults{algorithmType}.macroMRR.stddev; 
    end
        
    %% avgAccuracy_testSet_perAlgorithm
    
    function [mean stddev] = avgAccuracy_testSet_perAlgorithm(this, algorithmType)
        mean   = this.m_algorithmResults{algorithmType}.accuracy.mean;
        stddev = this.m_algorithmResults{algorithmType}.accuracy.stddev; 
    end
    
    %% avgAccuracy_testSet_allAlgorithms
    
    function R = avgAccuracy_testSet_allAlgorithms(this)
        algorithmsInResult = MultipleRunsResult.algorithmsResultOrder();
        numAlgorithms = length(algorithmsInResult);
        R = zeros(1, numAlgorithms);
        table_i = 1;
        for algorithm_i=algorithmsInResult
            if algorithm_i <= length(this.m_algorithmResults) && ...
               ~isempty(this.m_algorithmResults{algorithm_i})
                result = this.m_algorithmResults{algorithm_i};
                avgAccuracy = result.accuracy.mean;
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
             SingleRun.MAD ...
             SingleRun.AM];
    end
end

end % classdef