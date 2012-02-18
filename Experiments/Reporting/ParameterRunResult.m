classdef ParameterRunResult < handle
    %PARAMETERRUNRESULTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_results; % indexed by optimization method
        m_parameterValues;
        m_constructionParams;
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
 
end
    
end

