classdef ExperimentRun < handle
    %EXPERIMENTRUN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        m_constructionParams;
    end %(Access = public)
    
    properties (SetAccess = public, GetAccess=public)
        m_graph;
        m_parameterRuns;
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
        this.m_graph = GraphLoader.constructGraph(this.m_constructionParams);
    end
    
    %% removeExtraSplitVertices
    
    function removeExtraSplitVertices(this)
        this.m_graph = GraphLoader.removeExtraSplitVertices...
            (this.m_graph,  this.m_constructionParams.numFolds);
    end
    
    %% createEvaluationRun
    
    function R = createEvaluationRun(this)
        R = EvaluationRun;
        R.m_constructionParams = this.m_constructionParams;
        R.m_graph = this.m_graph;
    end
    
    %% addParameterRun
    
    function addParameterRun(this, value)
        this.m_parameterRuns = [this.m_parameterRuns;value];
    end
    
    %% getParameterRun
    
    function R = getParameterRun(this, index)
        R = this.m_parameterRuns(index);
    end
    
    %% numParameterRuns
    
    function R = numParameterRuns(this)
        R = length(this.m_parameterRuns);
    end

end
    
end

