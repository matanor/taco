classdef ExperimentRun < handle
    %EXPERIMENTRUN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        m_constructionParams;
    end %(Access = public)
    
    properties (SetAccess = private, GetAccess=public)
        m_graph;
    end
    
methods (Access = public)
    %% set_constructionParams
    
    function set_constructionParams(this, value)
        this.m_constructionParams = value;
    end
    
    %% getGraph
    
    function R = getGraph(this)
        R = this.m_graph;
    end    
    
    %% constructGraph
    
    function constructGraph(this)
        
        constructionParams = this.m_constructionParams;
        
        ConstructionParams.display(constructionParams);
            
        this.m_graph = GraphLoader.loadAll( constructionParams.fileName );
        
        this.removeExtraSplitVertices();
        
        this.m_graph.w_nn = knn(this.m_graph.weights, constructionParams.K);

        this.m_graph.w_nn_symetric = makeSymetric(this.m_graph.w_nn);
        
%         this.createTrunsductionSplit();
    end
    
    %% removeExtraSplitVertices
    
    function removeExtraSplitVertices(this)
        graph = this.m_graph;
        numFolds = this.m_constructionParams.numFolds;
        
        numVertices = length(graph.labels);
        newNumVertices = numVertices - mod(numVertices, numFolds);
        verticesToRemove = (newNumVertices+1):numVertices;
            
        graph.labels(verticesToRemove) = [];
        graph.weights(verticesToRemove,:) = [];
        graph.weights(:,verticesToRemove) = [];
        
        this.m_graph = graph;
    end
    
    %% createEvaluationRun
    
    function R = createEvaluationRun(this)
        R = EvaluationRun;
        R.m_constructionParams = this.m_constructionParams;
        R.m_graph = this.m_graph;
    end

end
    
end

