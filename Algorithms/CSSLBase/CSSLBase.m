classdef CSSLBase < GraphTrunsductionBase
% Base class for CSSL algorithms

    properties (SetAccess=public, GetAccess=protected)
        m_alpha;
        m_beta;
        m_labeledConfidence;
        m_zeta;
        m_useGraphHeuristics;
        m_isUsingL2Regularization;
        m_isUsingSecondOrder;
        m_descendMode;
        
        m_p; % controlled random walk probabilities;
        
        m_structuredInfo;
        m_isUsingStructured;
        m_isCalcObjective;
    end
    
properties( Constant)
    % Fix mu and sigma.
    % Calculate new mu and sigma according to fixed values.
    % This version was used for experiment in the ECML paper.
    DESCEND_MODE_COORIDNATE_DESCENT = 1;
    % Fix mu and sigma.
    % Calculate new mu according to fixed values.
    % Update mu <- new mu.
    % Calculate new sigmas accoring to new mus.
    DESCEND_MODE_2 = 2;
    % Alternating minimization
    % Random order for updated of mus.
    % For each single mu(i), calculate new mu(i) and update.
    % These means following updates are influenced by each update.
    % After updating all mus, update all sigmas (can be independently).
    DESCEND_MODE_AM = 3;
end

properties( Constant)
    % if a vertex next/previous vertex is
    % the constant STRUCTURED_NO_VERTEX, it means the
    % vertex has no next/previous vertex
    STRUCTURED_NO_VERTEX = 0;
end

methods (Access=public)
    
    function this = CSSLBase() % constructor
        this.m_useGraphHeuristics = 0;
        this.m_descendMode = CSSLBase.DESCEND_MODE_COORIDNATE_DESCENT;
        this.m_isUsingStructured = 0;
        this.m_isCalcObjective = 0;
    end
    
    %% setTransitionMatrix
    
    function setTransitionMatrix(this, value)
        this.m_structuredInfo.transitionMatrix = value;
    end
    
    %% setVertexOrder
    
    function setVertexOrder(this, vertexOrder)
        next = vertexOrder + 1;
        next( next > this.numVertices() ) = this.STRUCTURED_NO_VERTEX;
        prev = vertexOrder - 1;
        prev( prev < 1 ) = this.STRUCTURED_NO_VERTEX;
        this.m_structuredInfo.next = next;
        this.m_structuredInfo.previous = prev;
    end
    
end %methods (Access=public)
    
methods (Access=protected)
    
    function displayParams(this, algorithmName)
        numVertices =  this.numVertices();
        paramsString = ...
                [' alpha = '                num2str(this.m_alpha) ...
                 ' beta = '                 num2str(this.m_beta) ...
                 ' gamma = '                num2str(this.m_labeledConfidence) ...
                 ' zeta = '                 num2str(this.m_zeta) ...
                 ' structured = '           num2str(this.m_isUsingStructured)...
                 ' with l2 = '              num2str(this.m_isUsingL2Regularization)...
                 ' using 2nd order = '      num2str(this.m_isUsingSecondOrder)...
                 ' descend mode = '         num2str(this.m_descendMode) ...
                 ' useGraphHeuristics = '   num2str(this.m_useGraphHeuristics) ...
                 ' maxIterations = '        num2str(this.m_num_iterations)...
                 ' num vertices = '         num2str(numVertices) ];                
        Logger.log(['Running ' algorithmName '.' paramsString]);
    end
    
    %% transitionMatrix
    
    function R = transitionMatrix(this)
        R = this.m_structuredInfo.transitionMatrix;
    end
    
    %% transitionsToState
    
    function R = transitionsToState(this, state_i)
        R = this.m_structuredInfo.transitionMatrix(state_i, :);
    end
    
    %% setNextVertices
    
    function setNextVertices(this, value)
        assert(this.numVertices == size(value,1));
        this.m_structuredInfo.next = value;
    end
    
    %% setPreviousVertices
    
    function setPreviousVertices(this, value)
        assert(this.numVertices == size(value,1));
        this.m_structuredInfo.previous = value;
    end
    
    %% getNextVertexIndex
    
    function R = getNextVertexIndex( this, vertex_i )
        R = this.m_structuredInfo.next(vertex_i);
    end
    
    %% getPreviousVertexIndex
    
    function R = getPreviousVertexIndex( this, vertex_i )
        R = this.m_structuredInfo.previous(vertex_i);
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

