classdef EvaluationRun < handle
    %EVALUATIONRUN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        m_constructionParams;
        m_graph;
        m_parameterTuningRuns;
        m_evaluationRuns;
    end
    
methods (Access = public)
    %% setParameterTuningRuns
    
    function setParameterTuningRuns(this, algorithmType, value)
        this.m_parameterTuningRuns{algorithmType} = value;
    end
    
    %% numOptimizationRuns
    
    function R = numOptimizationRuns(this, algorithmType)
        R = length(this.m_parameterTuningRuns{algorithmType});
    end
    
    %% getOptimizationRun
    
    function R = getOptimizationRun(this, algorithmType, index)
        allOptimizationRuns = this.m_parameterTuningRuns{algorithmType};
        R = allOptimizationRuns(index);
    end
    
    %% setEvaluationRuns
    
    function setEvaluationRuns(this, value)
        this.m_evaluationRuns = value;
    end
    
    %% numEvaluationRuns
    
    function R = numEvaluationRuns(this)
        R = length(this.m_evaluationRuns);
    end
    
    %% getEvaluationRun
    
    function R = getEvaluationRun(this)
        R = this.m_evaluationRuns;
    end
    
    %% algorithmsRange
    
    function R = algorithmsRange(this)
        R = [];
        maxAlgorithmID = length(this.m_parameterTuningRuns);
        for algorithm_i=1:SingleRun.numAvailableAlgorithms()
            if algorithm_i <= maxAlgorithmID && ...
               ~isempty(this.m_parameterTuningRuns{algorithm_i})
                R = [R algorithm_i]; %#ok<AGROW>
            end
        end
    end
    
    %% optimalParams
    
    function R = optimalParams(this, algorithmType)
        tuneRuns = this.m_parameterTuningRuns{algorithmType};
        numTuningRuns = length(tuneRuns);
        scores = zeros(numTuningRuns ,1);
        for tuning_run_i=1:numTuningRuns 
            scores(tuning_run_i) = this.evaluateRun...
                ( tuneRuns( tuning_run_i ), algorithmType );
        end
        [~,bestRunIndex] = max(scores);
        R = tuneRuns(bestRunIndex).getParams( algorithmType );
    end
    
    %% evaluateRun
    
    function R = evaluateRun(~, singleRun, algorithmType)
        R = singleRun.calcAveragePRBEP_testSet(algorithmType);
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
                
        graph.folds = GraphLoader.split(graph, constructionParams.numFolds );
            
        trainingSet = graph.folds(1,:);
        graph.labeledVertices  = GraphLoader.selectLabelsUniformly...
                            (   trainingSet, ...
                                graph.labels, ...
                                constructionParams.classToLabelMap, ...
                                ConstructionParams.numLabeledPerClass(constructionParams) );
                            
        this.m_graph = graph;
                            
        %labeledVertices = GraphLoader.selectLabeled_atLeastOnePerLabel...
        %                    ( folds(1,:), graph.labels, classToLabelMap, numLabeled); 

        % unlabeled instances from train set
        % trainSetUnlabeled = setdiff(folds(1,:), labeledVertices);

        %[graph labeledVertices] = ...
        %    ExperimentRun.removeVertices...
        %        ( graph, labeledVertices, trainSetUnlabeled );
    end
end
    
end

