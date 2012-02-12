classdef EvaluationRun < handle
    %EVALUATIONRUN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        m_constructionParams;
        m_graph;
        m_parameterTuningRunsJobNames;
        m_evaluationRunsJobNames;
        m_evaluationParams;
    end
    
methods (Access = public)
    %% set_evaluationParams
    
    function set_evaluationParams( this, value)
        this.m_evaluationParams = value;
    end
    
    %% get_evaluationParams
    
    function R = get_evaluationParams(this)
        R = this.m_evaluationParams;
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
        R = this.m_evaluationParams.numEvaluationRuns;
    end
    
    %% optimizationMethodsCollection
    
    function R = optimizationMethodsCollection(this)
        R = this.m_evaluationParams.optimizeByCollection;
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

    %% createSingleRunFactory
    
    function singleRunFactory = createSingleRunFactory(this)
        singleRunFactory = SingleRunFactory;
        singleRunFactory.m_constructionParams   = this.m_constructionParams;
        singleRunFactory.m_graph                = this.m_graph;
    end
    
    %% createTrunsductionSplit
    
    function createTrunsductionSplit(this)
        graph = this.m_graph;
        constructionParams = this.m_constructionParams;
               
        if (this.m_evaluationParams.balancedFolds)
            graph.folds = GraphLoader.splitBalanced(graph, constructionParams.numFolds );
        else
            graph.folds = GraphLoader.split(graph, constructionParams.numFolds );
        end
            
        trainingSet = graph.folds(1,:);
        if (this.m_evaluationParams.balancedLabeled)
            graph.labeledVertices  = GraphLoader.selectLabelsUniformly...
                            (   trainingSet, ...
                                graph.labels, ...
                                constructionParams.classToLabelMap, ...
                                ConstructionParams.numLabeledPerClass(constructionParams) );
        else
            graph.labeledVertices = GraphLoader.selectLabeled_atLeastOnePerLabel...
                (   trainingSet, ...
                    graph.labels,...
                    constructionParams.classToLabelMap, ...
                    constructionParams.numLabeled); 
        end
                            
        this.m_graph = graph;
                            

        % unlabeled instances from train set
        % trainSetUnlabeled = setdiff(folds(1,:), labeledVertices);

        %[graph labeledVertices] = ...
        %    ExperimentRun.removeVertices...
        %        ( graph, labeledVertices, trainSetUnlabeled );
    end
end

methods (Static)
    %% calcOptimalParams
    
    function [R, bestValue] = calcOptimalParams(tuneRuns, algorithmType, optimizeBy)
        numTuningRuns = length(tuneRuns);
        scores = zeros(numTuningRuns ,1);
        for tuning_run_i=1:numTuningRuns 
            scores(tuning_run_i) = EvaluationRun.doEvaluateRun...
                ( tuneRuns( tuning_run_i ), algorithmType, optimizeBy );
        end
        [bestValue,bestRunIndex] = max(scores);
        R = tuneRuns(bestRunIndex).getParams( algorithmType );
    end
    
    %% doEvaluateRun
    
    function R = doEvaluateRun(singleRun, algorithmType, optimizeBy)
        params = singleRun.getParams(algorithmType);
        paramsString = Utilities.StructToStringConverter(params);
        disp(paramsString);
        if (optimizeBy == ParamsManager.OPTIMIZE_BY_ACCURACY) 
            R = singleRun.accuracy_testSet(algorithmType);
            disp(['Accuracy = ' num2str(R)]);
        else
            R = singleRun.calcAveragePRBEP_testSet(algorithmType);
            disp(['Average PRBEP = ' num2str(R)]);
        end
    end
end
    
end

