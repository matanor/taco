classdef GraphTrunsductionBase < handle
    %GRAPHTRUNSDUCTIONBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_priorY;           % Y - prior labeling, its size should be
                            %       number of vertices X number of labels.
        m_labeledSet;       % indices of labeled vertices.
        m_isLabeledVector;  % 1 - for labeled vertices, otherwise 0.
        m_W;                % The weights of the graph.
        m_num_iterations;
        m_useClassPriorNormalization;
        m_save_all_iterations; % 1 - save all iterations info in algorithm output
                               % 0 - algorithm output is only the final
                               % values.
        m_diffEpsilon;
    end
    
methods
    
    function this = GraphTrunsductionBase()
        this.m_useClassPriorNormalization = 1; % use class prior normalization by default.
        this.m_save_all_iterations = 0;
        this.m_diffEpsilon          = 0.0001; %0.0000001; 
    end
    
    %% numVertices
    
    function R = numVertices(this)
         R = size(this.m_W,1);
    end
    
    %% numLabels
    
    function R = numLabels(this)
        R = size(this.m_priorY,2);
    end
    
    %% isLabeled
    
    function R = isLabeled(this, vertex_i)
        R = this.m_isLabeledVector(vertex_i);
    end
    
    %% priorVector
    
    function R = priorVector(this, vertex_i)
        R = this.m_priorY(vertex_i,:).';
    end
    
    %% priorLabelScore
    
    function R = priorLabelScore(this, vertex_i, label_j)
        R = this.m_priorY( vertex_i, label_j );
    end
    
    %% labeledSet
    
    function R = labeledSet(this)
        R = this.m_labeledSet;
    end
    
    %% setLabeledSet
    
    function setLabeledSet(this, value)
        this.m_labeledSet = value;
        this.m_isLabeledVector = zeros(this.numVertices(), 1);
        this.m_isLabeledVector(this.m_labeledSet) = 1;
    end
    
    %% createInitialLabeledY

    function createInitialLabeledY(this, graph, labeledInitMode)
        
        labeledInitMode = this.checkIfInitModeMathcesAlgorithm(labeledInitMode);
        
        numVertices = this.numVertices();
        numLabels = length( graph.availableLabels() );
        labeledVertices_indices         = this.labeledSet();
        labeledVertices_correctLabels   = ...
            graph.correctLabelsForVertices(labeledVertices_indices);
        
        R = zeros( numVertices, numLabels);
        availableLabels = 1:numLabels;
        
        for label_i=availableLabels
            labeledVerticesForClass = ...
                labeledVertices_indices(labeledVertices_correctLabels == label_i);
            % set +1 for lebeled vertex belonging to a class.
            R( labeledVerticesForClass, label_i ) = 1;
            if (labeledInitMode == ParamsManager.LABELED_INIT_MINUS_PLUS_ONE ||...
                labeledInitMode == ParamsManager.LABELED_INIT_MINUS_PLUS_ONE_UNLABELED)
                % set -1 for labeled vertex not belonging to other classes.
                otherLabels = setdiff(availableLabels, label_i);
                R( labeledVerticesForClass, otherLabels ) = -1;
            end
        end
        if (labeledInitMode == ParamsManager.LABELED_INIT_MINUS_PLUS_ONE_UNLABELED)
            % set -1 for unlabeled vertices not belonging to any class.
            unlabeled = setdiff( 1:numVertices, labeledVertices_indices );
            R( unlabeled, : ) = -1;
        end
        
        this.m_priorY = R;
    end
    
    %% checkIfInitModeMathcesAlgorithm
    
    function R = checkIfInitModeMathcesAlgorithm(this, labeledInitMode)
        % allow derived classes (specific algorithme) to change
        % the labels init mode if they don't like it.
        % e.g. for AM the labels prior must be a distribution, so we
        % cannot initialize any priorY entries to -1.
        R = labeledInitMode;
    end
    
    %% classPriorNormalization
    
    function classPriorNormalization(this)
        Logger.log('classPriorNormalization');
        Y = this.m_priorY;
        
        Y( this.m_priorY ~= 1) = 0; % remove all (-1) or other values set because of
                       % different label init modes.
        sumPerClass = sum(Y);
        maxSum = max(sumPerClass);
        multiplyByFactors = maxSum ./ sumPerClass;
        numVertices = this.numVertices();
        Logger.log(['multiplyByFactors = ' num2str(multiplyByFactors)]);
        multiplyByMatrix = repmat(multiplyByFactors, numVertices, 1);
        Y = Y .* multiplyByMatrix;
        
        Y( this.m_priorY ~= 1) = this.m_priorY(this.m_priorY ~= 1);
        
        % numCellsChanged = sum(sum(Y ~= this.m_priorY))
        this.m_priorY = Y;
    end

end
    
    
end

