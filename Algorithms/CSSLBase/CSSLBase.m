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
        m_structuredTermType;
        m_isCalcObjective;
        m_objectiveType;
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

%% Different kinds of structured terms
    
properties (Constant)
    NO_STRUCTURED_TERM = 0;
    STRUCTURED_TRANSITION_MATRIX = 1;
    STRUCTURED_LABELS_SIMILARITY = 2;
end

%% Different kinds of objectives

properties( Constant)
    % Objective based on harmonic mean between neighbouring uncertainty 
    % parameters. See Graph-Based Transduction with Confidence ECML 2012
    OBJECTIVE_HARMONIC_MEAN = 1;
    % Objective based on multiplicative factors for neighbouring 
    % uncertainty parameters. (20.11.2012)
    OBJECTIVE_MULTIPLICATIVE = 2;
    % Objective based on uncertainty parameters per edge. sigma_{i,j}
    OBJECTIVE_WEIGHTS_UNCERTAINTY = 3;
    % Objective based on additive factors in teh denominator for neighbouring 
    % uncertainty parameters. (20.11.2012)    
    OBJECTIVE_ADDITIVE = 4;
end

properties( Constant)
    % if a vertex next/previous vertex is
    % the constant STRUCTURED_NO_VERTEX, it means the
    % vertex has no next/previous vertex
    STRUCTURED_NO_VERTEX = 0;
end

methods (Access=public)
    
    %% constructor
    
    function this = CSSLBase() 
        this.m_useGraphHeuristics   = 0;
        this.m_descendMode          = CSSLBase.DESCEND_MODE_COORIDNATE_DESCENT;
        this.m_structuredTermType   = CSSLBase.NO_STRUCTURED_TERM;
        this.m_objectiveType        = CSSLBase.OBJECTIVE_HARMONIC_MEAN;
        this.m_isCalcObjective      = 0;
        this.m_structuredInfo.transitionMatrix = [];
    end
    
    %% setTransitionMatrix
    
    function setTransitionMatrix(this, value)
        this.m_structuredInfo.transitionMatrix = value;
    end
    
    %% setStructuredEdges
    
    function setStructuredEdges(this, structuredEdges)
        numVertices = this.numVertices();
        next = this.STRUCTURED_NO_VERTEX * zeros(numVertices, 1);
        prev = this.STRUCTURED_NO_VERTEX * zeros(numVertices, 1);
        numStructuredEdges = size(structuredEdges,1);
        if ~isempty(structuredEdges)
            assert( size(structuredEdges,2) == 2);
        end
        Logger.log(['setStructuredEdges. numStructuredEdges = ' num2str(numStructuredEdges)]);
        for edge_i=1:numStructuredEdges
            v1 = structuredEdges(edge_i, 1);
            v2 = structuredEdges(edge_i, 2);
            next(v1) = v2;
            prev(v2) = v1;
        end
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
                 ' structured = '           num2str(this.m_structuredTermType)...
                 ' objective = '            num2str(this.m_objectiveType)...
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
        if ~isempty(this.m_structuredInfo.transitionMatrix)
            R = this.m_structuredInfo.transitionMatrix;
        else
            R = [];
        end
    end
    
    %% transitionsToState
    
    function R = transitionsToState(this, state_i)
        R = this.m_structuredInfo.transitionMatrix(state_i, :);
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

