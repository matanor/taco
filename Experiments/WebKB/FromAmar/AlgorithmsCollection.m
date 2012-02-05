classdef AlgorithmsCollection < handle
    %ALGORITHMSCOLLECTION Summary of this class goes here
    %   Detailed explanation goes here
    
properties (Access = public)
    m_algorithms;
end

methods (Access = public)
    
    function this = AlgorithmsCollection()
        numAlgorithms = SingleRun.numAvailableAlgorithms();
        this.m_algorithms = zeros( numAlgorithms, 1);
    end
    
    function setRun(this, algorithmType)
        this.m_algorithms(algorithmType) = 1;
    end
    
    function R = shouldRun(this, algorithmsType)
        R = this.m_algorithms( algorithmsType );
    end
end
    
end

