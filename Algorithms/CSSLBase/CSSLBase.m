classdef CSSLBase < GraphTrunsductionBase
% Base class for CSSL algorithms

    properties (SetAccess=public, GetAccess=protected)
        m_alpha;
        m_beta;
        m_labeledConfidence;
        m_useGraphHeuristics;
        m_isUsingL2Regularization;
        m_isUsingSecondOrder;
        
        m_p; % controlled random walk probabilities;
    end

methods (Access=public)
    
    function this = CSSLBase() % constructor
        this.m_useGraphHeuristics = 0;
    end
    
end %methods (Access=public)
    
methods (Access=protected)
    
    function displayParams(this, algorithmName)
        numVertices =  this.numVertices();
        paramsString = ...
                [' alpha = '                num2str(this.m_alpha) ...
                 ' beta = '                 num2str(this.m_beta) ...
                 ' gamma = '                num2str(this.m_labeledConfidence) ...
                 ' with l2 = '              num2str(this.m_isUsingL2Regularization)...
                 ' using 2nd order = '      num2str(this.m_isUsingSecondOrder)...
                 ' useGraphHeuristics = '   num2str(this.m_useGraphHeuristics) ...
                 ' maxIterations = '        num2str(this.m_num_iterations)...
                 ' num vertices = '         num2str(numVertices) ];                
        Logger.log(['Running ' algorithmName '.' paramsString]);
    end
    
    %% prepareGraph
    
    function prepareGraph(this)
        labeledVertices = this.labeledSet();
        if (this.m_useGraphHeuristics ~=0)
            p = MAD.calcProbabilities(this.m_W, labeledVertices);
            this.m_p = p;
            this.updateGraphUsingHeuristics(p);
        end
    end
    
    %% updateGraphUsingHeuristics
    
    function updateGraphUsingHeuristics(this, p)
        num_vertices = size( this.m_W, 1);
        for vertex_j=1:num_vertices
            p_cont_j = p.continue(vertex_j);
            for vertex_i=1:num_vertices
                continueFactor = p.continue(vertex_i) + p_cont_j;
                this.m_W(vertex_i, vertex_j) = ...
                    continueFactor * this.m_W(vertex_i, vertex_j);
            end
        end
    end
    
    %% injectionProbability
    
    function r = injectionProbability( this, vertex_i )
        r = this.isLabeled(vertex_i);
        if (this.m_useGraphHeuristics ~=0)
            r = r * this.m_p.inject(vertex_i);
        end
    end
    
end % methods (Access=protected)
    
end % classdef

