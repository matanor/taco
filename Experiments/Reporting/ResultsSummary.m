classdef ResultsSummary < handle
    %RESULTSSUMMARY Summary of this class goes here
    %   Detailed explanation goes here
    
properties
    m_resultCollection;
end

methods
    %% add
    
    function add(this, experimentRunResult)
        this.m_resultCollection = ...
            [this.m_resultCollection experimentRunResult];
    end
    
    %% printSummary
    
    function printSummary(this)
        numExperiments = length(this.m_resultCollection);
        for experiment_i=1:numExperiments
            experimentRunResult = this.m_resultCollection (experiment_i);
            experimentRunResult.printSummary();
        end
    end
end
    
end

