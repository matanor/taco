classdef CSSLBase < handle
% Base class for CSSL algorithms

    properties (SetAccess=public, GetAccess=protected)
        m_W;
        m_num_iterations;
        m_alpha;
        m_beta;
        m_labeledConfidence;
        m_useGraphHeuristics;
        
        m_p; % controlled random walk probabilities;
    end

methods (Access=public)
    
end %methods (Access=public)
    
methods (Access=protected)
    
    function prepareGraph(this, labeledY)
        labeledVertices = find(sum(labeledY,2) ~=0 );
        if (this.m_useGraphHeuristics ~=0)
            p = MAD.calcProbabilities(this.m_W, labeledVertices); %#ok<FNDSB>
            this.m_p = p;
            this.updateGraphUsingHeuristics(p);
        end
    end
    
    function updateGraphUsingHeuristics(this, p)
        num_vertices = size( this.m_W, 1);
        for vertex_i=1:num_vertices
            for vertex_j=1:num_vertices
                continueFactor = p.continue(vertex_i) + p.continue(vertex_j);
                this.m_W(vertex_i, vertex_j) = ...
                    continueFactor * this.m_W(vertex_i, vertex_j);
            end
        end
    end
    
    function r = injectionProbability( this, vertex_i, y_i )
        r = (sum(y_i) ~=0) ;
        if (this.m_useGraphHeuristics ~=0)
            r = r * this.m_p.inject(vertex_i);
        end
    end
end % methods (Access=protected)
    
end % classdef

