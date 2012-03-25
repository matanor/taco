classdef ExperimentRun < handle
    %EXPERIMENTRUN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        m_constructionParams;
    end %(Access = public)
    
    properties (SetAccess = public, GetAccess=public)
        m_graph;
        m_parameterRuns;
        m_trunsductionSets;
    end
    
methods (Access = public)
    
    %% constructor
    
    function this = ExperimentRun(constructionParams)
        this.m_graph = ExperimentGraph;
        this.m_constructionParams = constructionParams;
    end

    %% get_constructionParams
    
    function R = get_constructionParams(this)
        R = this.m_constructionParams;
    end
    
    %% constructGraph
    
    function constructGraph(this)
        this.m_graph.load                    ( this.m_constructionParams.fileName );
        this.m_graph.removeExtraSplitVertices( this.m_constructionParams.numFolds);
        
        trunsductionSetsFactory = ...
            ExperimentTrunsductionSetsFactory( this.m_constructionParams, this.m_graph );
        this.m_trunsductionSets = trunsductionSetsFactory.create();
    end
    
    %% saveTrunsductionSets
    
    function saveTrunsductionSets(this, outputFileFullPath )
        disp(['Saving trunsduction sets to ' outputFileFullPath '''']);
        trunsductionSets = this.m_trunsductionSets; %#ok<NASGU>
        save(outputFileFullPath, 'trunsductionSets');
    end
    
    %% createParameterRun
    
    function R = createParameterRun(this, parameterValues)
        R = ParameterRun(this.m_constructionParams, this.m_graph, ...
                         this.m_trunsductionSets,   parameterValues);
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

