classdef ParameterRunResult < handle
    %PARAMETERRUNRESULTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_results; % indexed by optimization method
        m_parameterValues;
        m_constructionParams;
        m_optimalParams;
    end
    
methods
    %% optimizationMethodsCollection
    
    function R = optimizationMethodsCollection(this)
        R = this.m_parameterValues.optimizeByCollection;
    end
    
    %% create
    
    function create(this, parameterRun, constructionParams)
        this.m_constructionParams = constructionParams;
        this.m_parameterValues = parameterRun.get_paramValues();
        this.m_optimalParams = parameterRun.get_optimalParams();
        
        optimizationMethods = this.optimizationMethodsCollection();
        for optimization_method_i=optimizationMethods
            disp(['optimized by = ' OptimizationMethodToStringConverter.convert(optimization_method_i) ]);
            allEvaluationRuns = MultipleRuns;
            numEvaluationRuns = parameterRun.numEvaluationRuns();
            for evaluation_run_i=1:numEvaluationRuns
                evaluationRunJobName = ...
                    parameterRun.getEvaluationRunJobName...
                        (optimization_method_i, evaluation_run_i);
                evaluation_run = JobManager.loadJobOutput(evaluationRunJobName);
                allEvaluationRuns.addRun(evaluation_run);
            end
            multipleRunResult = MultipleRunsResult;
            multipleRunResult.create(allEvaluationRuns );
            this.m_results{optimization_method_i} = multipleRunResult;
        end
    end
    
    %% get_optimalParams
    
    function R = get_optimalParams(this, optimization_method_i, algorithm_i)
        if optimization_method_i <= size(this.m_optimalParams,1) && ...
           algorithm_i           <= size(this.m_optimalParams,2)
            R = this.m_optimalParams{optimization_method_i,algorithm_i};
        else
            R = [];
        end;
    end
    
    %% resultsTablePRBEP
    
    function R = resultsTablePRBEP(this,optimization_method_i, isEstimated)
        R = this.m_results{optimization_method_i}.resultsTablePRBEP(isEstimated);
    end
    
    %% avgAccuracy_testSet
    
    function R = avgAccuracy_testSet(this, optimization_method_i)
        R = this.m_results{optimization_method_i}.avgAccuracy_testSet();
    end
    
    %% parameterValues
    
    function R = parameterValues(this)
        R = Utilities.combineStructs_removeDuplicates...
            (this.m_parameterValues, this.m_constructionParams);
    end
    
    %% isUsingHeuristics
    
    function R = isUsingHeuristics(this)
        R = this.m_parameterValues.useGraphHeuristics;
    end
    
    %% numClasses
    
    function R = numClasses(this, optimization_method_i)
        R = this.m_results{optimization_method_i}.numClasses();
    end
    
    %% toString_all
    
    function R = toString_all(this)
        optimizationMethods = this.optimizationMethodsCollection();
        line_i = 1;
        for optimization_method_i=optimizationMethods
            multipleRunResult = this.m_results{optimization_method_i};
            algorithmsInResult = MultipleRunsResult.algorithmsResultOrder();
            
            for algorithm_i=algorithmsInResult
                if multipleRunResult.hasAlgorithmResult(algorithm_i)
                    S = this.toString(optimization_method_i, algorithm_i);
                    R{line_i} = S; %#ok<AGROW>
                    line_i = line_i + 1;
                end
            end
        end
    end
    
    %% toString
    
    function R = toString(this, optimization_method_i, algorithmType)
        fileName = FileHelper.fileName(this.m_constructionParams.fileName);
        SEPERATOR = ',';
        EMPTY_CELL = SEPERATOR ;
        R = [];
        R = [R fileName SEPERATOR ];
        R = [R num2str(this.m_constructionParams.balanced) SEPERATOR ];
        R = [R num2str(this.m_parameterValues.useGraphHeuristics) SEPERATOR ];
        R = [R num2str(this.m_parameterValues.labeledInitMode) SEPERATOR ];
        optimizationMethodName = OptimizationMethodToStringConverter.convert( optimization_method_i );
        R = [R optimizationMethodName SEPERATOR ];
        algorithmName = AlgorithmTypeToStringConverter.convert(algorithmType);
        R = [R algorithmName SEPERATOR ];
        isEstimated = 0;
        avgPRBEP = this.m_results{optimization_method_i}.avgPRBEP(algorithmType, isEstimated);
        R = [R num2str(avgPRBEP) SEPERATOR ];
        
        avgAccuracy = this.m_results{optimization_method_i} ...
                          .avgAccuracy_testSet_perAlgorithm(algorithmType);
        R = [R num2str(avgAccuracy) SEPERATOR ];
        
        [avgMRR stddevMRR] = this.m_results{optimization_method_i} ...
                     .avgMRR_testSet(algorithmType);
        R = [R num2str(avgMRR) ' (' num2str(stddevMRR) ')' SEPERATOR ];
        
        optimal = this.get_optimalParams(optimization_method_i, algorithmType);
        
        R = [R num2str(optimal.avgPRBEP) SEPERATOR ];
        R = [R num2str(optimal.avgAccuracy) SEPERATOR ];
        R = [R num2str(optimal.MRR) SEPERATOR ];
        
        O = OptimalParamsToStringConverter.convert ...
                    (optimal, algorithmType, EMPTY_CELL, SEPERATOR );
        R = [R O];
    end
 
end
    
end

