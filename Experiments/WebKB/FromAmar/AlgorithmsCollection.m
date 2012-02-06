classdef AlgorithmsCollection < handle
    %ALGORITHMSCOLLECTION Summary of this class goes here
    %   Detailed explanation goes here
    
properties (Access = public)
    m_algorithms;
end

methods (Access = public)
    
    function this = AlgorithmsCollection()
        numAlgorithms = AlgorithmsCollection.numAlgorithms();
        this.m_algorithms = zeros( numAlgorithms, 1);
    end
    
    function setRun(this, algorithmType)
        this.m_algorithms(algorithmType) = 1;
    end
    
    function R = shouldRun(this, algorithmsType)
        R = this.m_algorithms( algorithmsType );
    end
    
    function R = algorithmsRange(this)
        R = [];
        for algorithm_i=1:AlgorithmsCollection.numAlgorithms()
            if this.shouldRun( algorithm_i) 
                R = [R algorithm_i]; %#ok<AGROW>
            end
        end
    end
end

methods (Static)
    function R = numAlgorithms()
        R = SingleRun.numAvailableAlgorithms();
    end
end % methods (Static)

end

