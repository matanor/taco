classdef ExperimentTrunsductionSetsFactory < handle
    %EXPERIMENTTRUNSTUCTIONSSETSFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
properties
    m_constructionParams;
    m_graph;
end
    
methods
    %% Constructor
    
    function this = ExperimentTrunsductionSetsFactory( constructionParams, graph )
        this.m_constructionParams   = constructionParams;
        this.m_graph                = graph;
    end
    
    %% create
    
    function R = create(this)
        R = ExperimentTrunsductionSets;
        this.createOptimizationSets ( R, 1);
        this.createEvaluationSets   ( R, this.m_constructionParams.numEvaluationRuns);
        R.setCorrectLabels( this.m_graph.correctLabels() );
    end
    
    %% createOptimizationSets
    
    function createOptimizationSets(this, trunsductionSets, numSets)
         for set_i=1:numSets
             newSet = this.createTrunsductionSet();
             trunsductionSets.addOptimizationSet( newSet );
         end
    end
    
    %% createEvaluationSets
    
    function createEvaluationSets(this, trunsductionSets, numSets )
         for set_i=1:numSets
             newSet = this.createTrunsductionSet();
             trunsductionSets.addEvaluationSet( newSet );
         end
    end
    
    %% createTrunsductionSet
    
    function R = createTrunsductionSet(this)
        isBalanced      = this.m_constructionParams.balanced;
        numFolds        = this.m_constructionParams.numFolds;
        numLabeled      = ExperimentRun.precentLabeledToNumLabeled(this.m_constructionParams);
        
        splitter = Splitter(this.m_graph);
        trunsductionSet = splitter.create(isBalanced, numFolds);
        trunsductionSet.selectLabeled(this.m_graph, isBalanced, ...
                                      numLabeled);
        R = trunsductionSet;
    end
    
end
    
end

