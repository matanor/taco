classdef ExperimentTrunsductionSets < handle
    %EXPERIMENTTRUNSDUCTIONSETS Summary of this class goes here
    %   Detailed explanation goes here
    
properties
    m_optimizationSets;
    m_evaluationSets;
end
    
methods
    %% addEvaluationSet
    
    function addEvaluationSet( this, set )
        this.m_evaluationSets = [this.m_evaluationSets; set];
    end
    
    %% addOptimizationSet
    
    function addOptimizationSet( this, set )
        this.m_optimizationSets = [this.m_optimizationSets; set];
    end

    %% evaluationSet
    
    function R = evaluationSet(this, set_i)
        R = this.m_evaluationSets(set_i);
    end
    
    %% optimizationSet
    
    function R = optimizationSet(this, set_i)
        R = this.m_optimizationSets(set_i);
    end
    
    %% evalutionSet
    
    function R = evalutionSet(this, set_i)
        R = this.m_evaluationSets(set_i);
    end
    
end
    
end

