classdef ParameterRun < handle
    %PARAMETERRUN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        m_constructionParams;
        m_graph;
        m_parameterTuningRunsJobNames;
        m_evaluationRunsJobNames;
        m_parameterValues;
        m_trunsductionSets;
        m_optimalParams;
    end
    
methods (Access = public)
    %% Constructor
    
    function this = ParameterRun...
            ( constrcutionParams, graph, trunsductionSets, parameterValues)
        this.m_constructionParams = constrcutionParams;
        this.m_graph              = graph;
        this.m_trunsductionSets   = trunsductionSets;
        this.m_parameterValues    = parameterValues;
    end
    
    %% set_optimalParams
    
    function set_optimalParams(this, value)
        this.m_optimalParams = value;
    end
    
    %% get_optimalParams
    
    function R = get_optimalParams(this)
        R = this.m_optimalParams;
    end
    
    %% get_optimalParams_perOptimizationMethod
    
    function R = get_optimalParams_perOptimizationMethod...
                    (this, optimization_method_i, algorithmsToRun)
        for algorithm_i=algorithmsToRun.algorithmsRange()
            R{algorithm_i} = ...
                this.m_optimalParams{optimization_method_i,algorithm_i}.values; %#ok<AGROW>
        end
    end
    
    %% get_paramValues
    
    function R = get_paramValues(this)
        R = this.m_parameterValues;
    end
    
    %% setParameterTuningRunsJobNames
    
    function setParameterTuningRunsJobNames(this, algorithmType, value)
        this.m_parameterTuningRunsJobNames{algorithmType} = value;
    end
    
    %% numOptimizationRuns
    
    function R = numOptimizationRuns(this, algorithmType)
        R = length(this.m_parameterTuningRunsJobNames{algorithmType});
    end
    
    %% get_optimizationJobNames_perAlgorithm
    
    function R = get_optimizationJobNames_perAlgorithm(this, algorithmType)
        R = this.m_parameterTuningRunsJobNames{algorithmType};
    end
    
    %% getOptimizationRunJobName
    
    function R = getOptimizationRunJobName(this, algorithmType, index)
        allOptimizationRunsJobNames = this.m_parameterTuningRunsJobNames{algorithmType};
        R = allOptimizationRunsJobNames{index};
    end
    
    %% setEvaluationRunsJobNames
    
    function setEvaluationRunsJobNames(this, value)
        this.m_evaluationRunsJobNames = value;
    end
    
    %% numEvaluationRuns
    
    function R = numEvaluationRuns(this)
        R = this.m_parameterValues.numEvaluationRuns;
    end
    
    %% optimizationMethodsCollection
    
    function R = optimizationMethodsCollection(this)
        R = this.m_parameterValues.optimizeByCollection;
    end
    
    %% getEvaluationJobNames_perOptimizationMethod
    
    function R = evaluationJobNames_perOptimizationMethod(this, optimization_method_i)
        R = this.m_evaluationRunsJobNames{optimization_method_i};
    end
    
    %% getEvaluationRunJobName
    
    function R = getEvaluationRunJobName(this, optimization_method_i, evaluation_i)
        evaluationsForOptimizationMethod = this.m_evaluationRunsJobNames{optimization_method_i};
        R = evaluationsForOptimizationMethod{evaluation_i};
    end
    
    %% algorithmsRange
    
    function R = algorithmsRange(this)
        R = [];
        maxAlgorithmID = length(this.m_parameterTuningRunsJobNames);
        for algorithm_i=1:SingleRun.numAvailableAlgorithms()
            if algorithm_i <= maxAlgorithmID && ...
               ~isempty(this.m_parameterTuningRunsJobNames{algorithm_i})
                R = [R algorithm_i]; %#ok<AGROW>
            end
        end
    end

    %% createOptimizationRunFactory
    
    function R = createOptimizationRunFactory(this, optimization_run_i)
        trunsductionSet = ...
            this.m_trunsductionSets.optimizationSet( optimization_run_i );
        R = SingleRunFactory...
            ( this.m_constructionParams, this.m_graph, trunsductionSet );
    end
    
    %% createEvaluationRunFactory
    
    function R = createEvaluationRunFactory(this, evaluation_run_i)
        trunsductionSet = ...
            this.m_trunsductionSets.evaluationSet( evaluation_run_i );
        R = SingleRunFactory...
            ( this.m_constructionParams, this.m_graph, trunsductionSet );
    end
    
end

methods (Static)
    %% calcOptimalParams
    
    function R = calcOptimalParams(tuneRuns, algorithmType, optimizeBy)
        numTuningRuns = length(tuneRuns);
        for tuning_run_i=1:numTuningRuns 
            Logger.log(['Optimization run ' num2str(tuning_run_i) ' out of ' num2str(numTuningRuns)]);
            scores(tuning_run_i) = ParameterRun.evaluateOptimizationRun...
                ( tuneRuns( tuning_run_i ), algorithmType, optimizeBy ); %#ok<AGROW>
        end
        
        switch optimizeBy
            case ParamsManager.OPTIMIZE_BY_ACCURACY
                optimizationScores = [scores.accuracy];
            case ParamsManager.OPTIMIZE_BY_PRBEP
                optimizationScores = [scores.avgPRBEP];
            case ParamsManager.OPTIMIZE_BY_MRR
                optimizationScores = [scores.MRR];
            case ParamsManager.OPTIMIZE_BY_MACRO_MRR
                optimizationScores = [scores.macroMRR];
            case ParamsManager.OPTIMIZE_BY_MACRO_ACCURACY
                optimizationScores = [scores.macroAccuracy];
            case ParamsManager.OPTIMIZE_BY_LEVENSHTEIN
                optimizationScores = [scores.levenshtein];
            otherwise
                Logger.log(['calcOptimalParams::error. unknown optimization method ' ...
                        num2str(optimizeBy)]);
        end
        
        [bestScore,bestRunIndex] = max(optimizationScores);
        Logger.log(['Optimal on run ' num2str(bestRunIndex) ' with value ' num2str(bestScore)]);
        bestRun = tuneRuns( bestRunIndex );
        R.accuracy      = bestRun.accuracy_testSet(algorithmType);
        R.macroAccuracy = bestRun.macroAccuracy_testSet(algorithmType);
        R.avgPRBEP      = bestRun.calcAveragePRBEP_testSet(algorithmType);
        R.MRR           = bestRun.calcMRR_testSet(algorithmType);
        R.macroMRR      = bestRun.calc_macroMRR_testSet(algorithmType);
        R.levenshtein   = bestRun.levenshteinDistance_testSet(algorithmType);
        R.values        = bestRun.getParams( algorithmType );
        Logger.log('Optimal run statistics: ');
        Logger.log(['Accuracy = '         num2str(R.accuracy)]);
        Logger.log(['macroAccuracy = '    num2str(R.macroAccuracy)]);
        Logger.log(['Average PRBEP = '    num2str(R.avgPRBEP)]);
        Logger.log(['MRR = '              num2str(R.MRR)]);
        Logger.log(['macro MRR = '        num2str(R.macroMRR)]);
        Logger.log(['Levenshtein = '      num2str(R.levenshtein)]);
    end
    
    %% evaluateOptimizationRun
    
    function R = evaluateOptimizationRun(singleRun, algorithmType, optimizeBy)
        params = singleRun.getParams(algorithmType);
        paramsString = Utilities.StructToStringConverter(params);
        Logger.log(paramsString);
        switch optimizeBy
            case ParamsManager.OPTIMIZE_BY_ACCURACY
                R.accuracy = singleRun.accuracy_testSet(algorithmType);
                Logger.log(['Accuracy = ' num2str(R.accuracy)]);
            case ParamsManager.OPTIMIZE_BY_PRBEP
                R.avgPRBEP = singleRun.calcAveragePRBEP_testSet(algorithmType);
                Logger.log(['Average PRBEP = ' num2str(R.avgPRBEP)]);
            case ParamsManager.OPTIMIZE_BY_MRR
                R.MRR = singleRun.calcMRR_testSet(algorithmType);
                Logger.log(['MRR = ' num2str(R.MRR)]);
            case ParamsManager.OPTIMIZE_BY_MACRO_MRR
                R.macroMRR = singleRun.calc_macroMRR_testSet(algorithmType);
                Logger.log(['macro MRR = ' num2str(R.macroMRR)]);
            case ParamsManager.OPTIMIZE_BY_MACRO_ACCURACY
                R.macroAccuracy = singleRun.macroAccuracy_testSet(algorithmType);
                Logger.log(['macro accuracy = ' num2str(R.macroAccuracy)]);
            case ParamsManager.OPTIMIZE_BY_LEVENSHTEIN
                R.levenshtein = singleRun.levenshteinDistance_testSet(algorithmType);
                Logger.log(['levenshtein = ' num2str(R.levenshtein)]);
            otherwise
                Logger.log(['evaluateOptimizationRun::error. unknown optimization method ' ...
                        num2str(optimizeBy)]);
        end
    end
    
end
    
end

