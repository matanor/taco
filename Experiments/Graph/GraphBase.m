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
    
    %% save_edgeFactored
    
    function save_edgeFactored(this, outputFileFullPath)
        outputFile = fopen(outputFileFullPath, 'w');
        numVertices = this.numVertices();
        for vertex_i=1:numVertices
            for vertex_j=(vertex_i+1):numVertices
                edgeWeight = this.m_weights(vertex_i,vertex_j);
                vname1 = this.vertexName(vertex_i);
                vname2 = this.vertexName(vertex_j);
                fprintf(outputFile, '%s %s %s\n', vname1, vname2, num2str(edgeWeight));
            end
        end
        fclose(outputFile);
    end
    
    %% save_nodeFactored
    %   each line is in the format:
    %   source,node_1,sim_1,...,node_n,sim_n
    %   for example, this is a square graph with some weights:
    %         0.5
    %       1 --- 2
    %   0.6 |     | 0.7
    %       3 --- 4
    %          1
    %   in node factored format:
    %   V1,V2,0.5,V3,0.6
    %   V2,V4,0.7
    %   V3,V4,1
    
    function save_nodeFactored(this, outputFileFullPath)
        outputFile = fopen(outputFileFullPath, 'w');
        numVertices = this.numVertices();
        SEPERATOR = ',';
        for vertex_i=1:numVertices
            line = this.vertexName(vertex_i);
            for vertex_j=(vertex_i+1):numVertices
                edgeWeight = this.m_weights(vertex_i,vertex_j);
                line = [line                       SEPERATOR ...
                        this.vertexName(vertex_j)  SEPERATOR ...
                        num2str(edgeWeight) ]; %#ok<AGROW>
            end
            line = [line '\n']; %#ok<AGROW>
            fprintf(outputFile, line);
        end
        fclose(outputFile);
    end
    
    %% save_correctLabels
    
    function save_correctLabels(this, outputFileFullPath)
        numVertices = this.numVertices();
        this.save_correctLabels_specificRange(outputFileFullPath, 1:numVertices);
    end
    
    %% save_correctLabels_specificRange
    
    function save_correctLabels_specificRange(this, outputFileFullPath, range)
        outputFile = fopen(outputFileFullPath, 'w');
        for vertex_i=range
            correctLabel = this.m_correctLabels(vertex_i);
            correctLabelName = ['L' num2str(correctLabel) ];
            vertexName = this.vertexName(vertex_i);
            fprintf(outputFile,'%s %s 1.0\n', vertexName, correctLabelName);
        end
        fclose(outputFile);
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
    
    %% availableLabels
    
    function R = availableLabels(this)
        R = unique(this.m_correctLabels).';
    end
    
    %% numAvailableLabels
    
    function R = numAvailableLabels(this)
        R = length( this.availableLabels() );
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

methods (Static)
    function S = vertexName(vertex_i)
        S = ['V' num2str(vertex_i)];
    end
end
    
end

