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
    end
    
    %% createTrunstuctionSets
    
    function createTrunstuctionSets(this)
        trunsductionSetsFactory = ...
            ExperimentTrunsductionSetsFactory( this.m_constructionParams, this.m_graph );
        this.m_trunsductionSets = trunsductionSetsFactory.create();
    end
    
    %% saveTrunsductionSets
    
    function saveTrunsductionSets(this, outputFileFullPath )
        Logger.log(['Saving trunsduction sets to ' outputFileFullPath '''']);
        trunsductionSets = this.m_trunsductionSets; %#ok<NASGU>
        save(outputFileFullPath, 'trunsductionSets');
    end
    
    %% loadTrunsductionSets
    
    function loadTrunsductionSets(this, fileFullPath, numLabeledRequired)
        Logger.log(['Loading trunsduction sets from ' fileFullPath '''']);
        fileData = load(fileFullPath);
        experimentTrunsductionSet = fileData.trunsductionSets;
        if (experimentTrunsductionSet.hasOptimizationSets())
            numLabeledFromFile = experimentTrunsductionSet.optimizationSet(1).numLabeled();
            Logger.log(['ExperimentRun::loadTrunsductionSets. num labeled in optimization' ...
                        ' trunsduction set (from file) = ' num2str(numLabeledFromFile)]);
            assert(numLabeledFromFile == numLabeledRequired);
        end
        if (experimentTrunsductionSet.hasEvaluationSets())
            for evaluation_set_i=1:experimentTrunsductionSet.numEvaluationSets()
                numLabeledFromFile = experimentTrunsductionSet.evaluationSet(1).numLabeled();
                Logger.log(['ExperimentRun::loadTrunsductionSets. num labeled in evaluation' ...
                            ' trunsduction set ' num2str(evaluation_set_i) ...
                            ' (from file) = ' num2str(numLabeledFromFile)]);
                assert(numLabeledFromFile == numLabeledRequired);
            end
        end
        
        this.m_trunsductionSets = experimentTrunsductionSet;
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

