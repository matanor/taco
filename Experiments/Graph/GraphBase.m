classdef GraphBase < handle
    %GRAPHBASE Summary of this class goes here
    %   Detailed explanation goes here
    
properties
    m_weights;
    m_correctLabels;
    m_fileName;
end
    
methods
    %% load
    
    function load(this, graphFileName)
        this.m_fileName = graphFileName;
        Logger.log(['Loading file ''' graphFileName '''']);
        fileData = load( graphFileName, 'graph' );
        
        this.m_weights = fileData.graph.weights;
        this.m_correctLabels = fileData.graph.labels;
        
        this.checkWeightsAndLabels();
        
        this.loadFromStruct( fileData );
    end
    
    %% loadFromSavedFileName
    
    function loadFromSavedFileName(this)
        this.load(this.m_fileName);
    end
    
    %% checkWeightsAndLabels
    
    function checkWeightsAndLabels(this)
        numLabels   = length(this.m_correctLabels);
        numVertices = size(this.m_weights, 1);
        if ( numLabels > numVertices)
            Logger.log(['checkWeightsAndLabels:: Warning.' 'Labels: ' num2str(numLabels) ...
                  '. Vertices: '        num2str(numVertices)]);
            verticesToRemove = (numVertices+1):numLabels;
            this.m_correctLabels(verticesToRemove) = [];
        elseif numLabels < numVertices
            Logger.log(['checkWeightsAndLabels:: Warning.' 'Labels: ' num2str(numLabels) ...
                  '. Vertices: '        num2str(numVertices)]);
            verticesToRemove = (numLabels+1):numVertices;
            this.m_weights(verticesToRemove,:) = [];
            this.m_weights(:,verticesToRemove) = [];
        end
    end
    
    %% loadFromStruct (hook for derived classes)
    
    function loadFromStruct(~, ~)
    end
    
    %% correctLabels
    
    function R = correctLabels(this)
        R = this.m_correctLabels;
    end
    
    %% numVertices
    
    function R = numVertices(this)
        if (~isempty(this.m_weights))
            assert( length(this.m_correctLabels) == size(this.m_weights, 1) );
        end
        R = length(this.m_correctLabels);
    end

    %% removeVertices
    
    function removeVertices(this, verticesToRemove)
        this.m_correctLabels(verticesToRemove) = [];
        this.m_weights(verticesToRemove,:) = [];
        this.m_weights(:,verticesToRemove) = [];
    end
    
    %% clearWeights
    
    function clearWeights(this)
        this.m_weights = [];
    end
    
    %% availabelLabels
    
    function R = availabelLabels(this)
        R = unique(this.m_correctLabels).';
    end
    
    %% verticesForLabel
    
    function R = verticesForLabel(this, label)
         R = find(this.m_correctLabels == label);
    end
    
    %% correctLabelsForVertices
    
    function R = correctLabelsForVertices(this, vertices)
        R = this.m_correctLabels(vertices);
    end
end
    
end

