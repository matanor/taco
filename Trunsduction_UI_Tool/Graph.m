classdef Graph < GraphBase
    %GRAPH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        m_vertexPosition;
        m_textPosition;
        m_vertexProperties;
    end % properties (Access = private)
    
    properties (Access = private)
        BINARY_NUM_LABELS;
        X;
        Y;
    end
    
    methods (Access = public)
        
        %% Constructor
        
        function this = Graph() 
            this.BINARY_NUM_LABELS = 2;
            this.X = 1;
            this.Y = 2;
            this.m_textPosition = [];
            this.m_vertexProperties = [];
        end
        
        %% save
        
        function save( this, fileName )
            graphAsStruct = this.asStruct();
            Graph.saveStruct( graphAsStruct, fileName );
        end

        %% load
        
        function load(this, fileName) 
           loadData = load(fileName, 'graph');
           this.loadFromStruct( loadData.graph );
        end
        
        %% loadFromStruct
        
        function loadFromStruct( this, graphStruct )
            this.m_weights = graphStruct.W;
            numVertices = this.numVertices();
            this.m_correctLabels  = zeros(numVertices, this.BINARY_NUM_LABELS);
            this.m_vertexPosition = zeros(numVertices, 2);
            this.m_textPosition = zeros(numVertices, 2);
           
            positive = graphStruct.labeled.positive;
            negative = graphStruct.labeled.negative;
            
            if isfield(graphStruct, 'vertexProperties')
                this.m_vertexProperties = graphStruct.vertexProperties;
            else
                this.m_vertexProperties = ...
                    struct('name',[],  ...
                           'showText', num2cell(ones(numVertices,1)), ...
                           'showArrow',num2cell(zeros(numVertices,1)),...
                           'orderIndex',num2cell(zeros(numVertices,1)));
            end
           
            for v_idx=1:length(positive)
                this.setVertexLabel( positive(v_idx), this.positiveLabel() );
            end
                   
            for v_idx=1:length(negative)
               this.setVertexLabel( negative(v_idx), this.negativeLabel() );
            end
           
            for v_idx=1:numVertices
               this.m_vertexPosition(v_idx, this.X) = ...
                   graphStruct.v_coordinates(v_idx,this.X);
               this.m_vertexPosition(v_idx, this.Y) = ...
                   graphStruct.v_coordinates(v_idx,this.Y);
            end
            
            if isfield(graphStruct, 'text_coordinates')
                for v_idx=1:numVertices
                    this.m_textPosition(v_idx, this.X) = ...
                        graphStruct.text_coordinates(v_idx,this.X);
                    this.m_textPosition(v_idx, this.Y) = ...
                       graphStruct.text_coordinates(v_idx,this.Y);
                end
            else
                textOffset = this.defaultTestOffset();
                this.m_textPosition = this.m_vertexPosition + ...
                                        repmat(textOffset, numVertices, 1);
            end
        end
        
        %% weights
        
        function r = weights(this)
            r = this.m_weights;
        end
        
        %% allVerticesPositions
        
        function r = allVerticesPositions(this)
            r = this.m_vertexPosition;
        end
        
        %% labeled_positive
        
        function r = labeled_positive(this)
            assert( this.numLabels() == this.BINARY_NUM_LABELS);
            isPositive = this.m_correctLabels( :, this.positiveLabel() );
            r = find( isPositive ~= 0);
        end
        
        %% labeled_negative
        
        function r = labeled_negative(this)
            assert( this.numLabels() == this.BINARY_NUM_LABELS);
            isNegative = this.m_correctLabels( :, this.negativeLabel() );
            r = find( isNegative ~= 0);
        end
        
        %% labeled
        
        function r = labeled(this)
            assert( this.numLabels() == this.BINARY_NUM_LABELS);
            r = [   this.labeled_positive(); 
                    this.labeled_negative() ];
        end
        
        %% numLabels
        
        function r = numLabels(this)
            r = size( this.m_correctLabels, 2 );
        end
        
        %% positiveLabel
        
        function r = positiveLabel(this)
            assert( this.numLabels() == this.BINARY_NUM_LABELS);
            r = 2; % positive label index
        end
        
        %% negativeLabel
        
        function r = negativeLabel(this)
            assert( this.numLabels() == this.BINARY_NUM_LABELS);
            r = 1; % negative label index
        end
        
        %% setVertexLabel
        
        function setVertexLabel(this, v_idx, label_idx)
            newLabel = zeros( 1, this.numLabels() );
            newLabel( label_idx ) = 1;
            this.m_correctLabels(v_idx,:) = newLabel;
        end
        
        %% clearLabels
        
        function clearLabels(this, v_idx )
            newLabel = zeros( 1, this.numLabels() );
            this.m_correctLabels(v_idx,:) = newLabel;
        end
        
        %% defaultTestOffset
        
        function R = defaultTestOffset(~)
            defautlTestOffsetXY = [0.08 0.05];
            R = defautlTestOffsetXY;
        end
        
        %% addVertex
        
        function R = addVertex(this, newVertexPosition)
            old_num_vertices = this.numVertices();
            newPosition = [ newVertexPosition.x newVertexPosition.y ];
            this.m_vertexPosition = [this.m_vertexPosition; newPosition];
            this.m_weights = [this.m_weights;
                        zeros(1,old_num_vertices)];
            this.m_weights = [this.m_weights  zeros(old_num_vertices+1,1)];
            this.m_correctLabels = [ this.m_correctLabels;
                               zeros(1,this.numLabels()) ];
            textPosition  = newPosition + this.defaultTestOffset();
            this.m_textPosition = [this.m_textPosition;textPosition];
            newVertexID = old_num_vertices+1;
            this.m_vertexProperties(newVertexID).showText = 1;
            this.m_vertexProperties(newVertexID).name = [];
            this.m_vertexProperties(newVertexID).showArrow = 0;
            this.m_vertexProperties(newVertexID).orderIndex = 0;
            R = newVertexID;
        end
        
        %% removeVertex
        
        function removeVertex( this, v_idx )
            this.m_vertexPosition(v_idx,:)=[];
            this.m_textPosition(v_idx,:)=[];
            this.m_vertexProperties(v_idx) = [];
            this.m_weights(v_idx,:)=[];
            this.m_weights(:,v_idx)=[];
            this.m_correctLabels(v_idx, :) = [];
        end
        
        %% addEdge
        
        function addEdge(this, v1_idx, v2_idx )
            weight = 1;
            this.setEdgeWeight( v1_idx, v2_idx, weight );
        end
        
        %% removeEdge
        
        function removeEdge(this, v1_idx, v2_idx )
            weight = 0;
            this.setEdgeWeight( v1_idx, v2_idx, weight );
        end
        
        %% getEdgeWeight
        
        function R = getEdgeWeight( this, v1_idx, v2_idx )
            R = this.m_weights(v1_idx, v2_idx);
        end
        
        %% setEdgeWeight
        
        function setEdgeWeight(this, v1_idx, v2_idx, weight )
            Logger.log([  'Setting edge between vertices ' ...
                    num2str(v1_idx) ' ' num2str(v2_idx) ...
                    ' to weight = ' num2str(weight) ]);
            if (v1_idx == v2_idx)
                Logger.log('Single node edge, skipping');
                return ;
            end
            this.m_weights(v1_idx, v2_idx) = weight;
            this.m_weights(v2_idx, v1_idx) = weight;
        end
        
        %% moveVertex
        
        function moveVertex(this, v_idx, newPosition)
            this.m_vertexPosition(v_idx,this.X) = newPosition.x;
            this.m_vertexPosition(v_idx,this.Y) = newPosition.y;
        end
        
        %% vertexPosition
        
        function r = vertexPosition( this, v_idx )
            r = [this.m_vertexPosition(v_idx,this.X) ...
                 this.m_vertexPosition(v_idx,this.Y)];
        end
        
        %% vertexTextPosition
        
        function r = vertexTextPosition( this, v_idx )
            r = [this.m_textPosition(v_idx,this.X) ...
                 this.m_textPosition(v_idx,this.Y)];
        end
        
        %% set_vertexTextPosition 
        
        function set_vertexTextPosition(this, v_idx, value)
            this.m_textPosition(v_idx,:) = value;
        end
        
        %% set_vertexTextOffset
        
        function set_vertexTextOffset(this, v_idx, value)
            pos = this.vertexTextPosition(v_idx);
            pos = pos + value;
            this.set_vertexTextPosition(v_idx, pos);
        end
        
        %% isShowText
        
        function r = isShowText(this, v_idx)
            r = this.m_vertexProperties(v_idx).showText;
        end
        
        %% set_showText
        
        function set_showText(this, v_idx, value)
            this.m_vertexProperties(v_idx).showText = value;
        end
        
        %% isShowArrow
        
        function r = isShowArrow(this, v_idx)
            r = this.m_vertexProperties(v_idx).showArrow;
        end
        
        %% set_showArrow
        
        function set_showArrow(this, v_idx, value)
            this.m_vertexProperties(v_idx).showArrow = value;
        end
        
        %% set_vertexName
        
        function set_vertexName(this, v_idx, value)
            this.m_vertexProperties(v_idx).name = value;
        end
        
        %% vertexName
        
        function r = vertexName(this,v_idx)
            
            r = this.m_vertexProperties(v_idx).name;
            vertexOrderIndex = this.vertexOrderIndex(v_idx);
            if vertexOrderIndex
                r = [num2str(vertexOrderIndex) r];
            end
        end
        
        %% vertexHasName
        
        function r = vertexHasName(this,v_idx)
            r = ~isempty(this.vertexName(v_idx));
        end

        %% set_vertexOrderIndex
        
        function set_vertexOrderIndex(this, v_idx, value)
            this.m_vertexProperties(v_idx).orderIndex = value;
            this.createStructuredEdges();
        end
        
        %% vertexOrderIndex
        
        function r = vertexOrderIndex(this,v_idx)
            r = this.m_vertexProperties(v_idx).orderIndex;
        end
        
        %% createStructuredEdges
        
        function createStructuredEdges(this)
            Logger.log('Creating structured edges');
            R = [];
            numVertices = this.numVertices();
            orderIndices = [this.m_vertexProperties.orderIndex];
            vertices     =  1:numVertices;
            [orderIndices sortOrder]= sort(orderIndices);
            sortedVertices = vertices(sortOrder);
            firstOrdered = find(orderIndices);
            for vertex_i=firstOrdered:(numVertices-1)
                index_start = orderIndices(vertex_i);
                index_end   = orderIndices(vertex_i+1);
                if index_start + 1 == index_end
                    edge_start = sortedVertices(vertex_i);
                    edge_end   = sortedVertices(vertex_i+1);
                    R = [R; edge_start edge_end]; %#ok<AGROW>
                    Logger.log(['start end = ' num2str([edge_start edge_end])]);
                end
            end
            this.m_structuredInfo.structuredEdges = R;
        end
        
    end % methods (Access = public)

    methods ( Static )
        function saveStruct(graph,fileName)
            save(fileName, 'graph' );
        end
    end
    
    methods (Access = private)
        
        function r = asStruct(this)
            r.W = this.m_weights;
            r.labeled.positive = this.labeled_positive();
            r.labeled.negative = this.labeled_negative();
            r.v_coordinates = this.m_vertexPosition;
            r.text_coordinates = this.m_textPosition;
            r.vertexProperties = this.m_vertexProperties;
        end
    end % methods (Access = private)
    
end

