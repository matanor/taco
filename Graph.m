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
        
        function this = Graph() % Constructor
            this.BINARY_NUM_LABELS = 2;
            this.X = 1;
            this.Y = 2;
            this.m_textPosition = [];
            this.m_vertexProperties = [];
        end
        
        function save( this, fileName )
            graphAsStruct = this.asStruct();
            Graph.saveStruct( graphAsStruct, fileName );
        end

        function load(this, fileName) 
           loadData = load(fileName, 'graph');
           this.loadFromStruct( loadData.graph );
        end
        
        function loadFromStruct( this, graphStrcut )
            this.m_weights = graphStrcut.W;
            numVertices = this.numVertices();
            this.m_correctLabels  = zeros(numVertices, this.BINARY_NUM_LABELS);
            this.m_vertexPosition = zeros(numVertices, 2);
            this.m_textPosition = zeros(numVertices, 2);
           
            positive = graphStrcut.labeled.positive;
            negative = graphStrcut.labeled.negative;
            
            this.m_vertexProperties = graphStrcut.vertexProperties;
           
            for v_idx=1:length(positive)
                this.setVertexLabel( positive(v_idx), this.positiveLabel() );
            end
                   
            for v_idx=1:length(negative)
               this.setVertexLabel( negative(v_idx), this.negativeLabel() );
            end
           
            for v_idx=1:numVertices
               this.m_vertexPosition(v_idx, this.X) = ...
                   graphStrcut.v_coordinates(v_idx,this.X);
               this.m_vertexPosition(v_idx, this.Y) = ...
                   graphStrcut.v_coordinates(v_idx,this.Y);
               this.m_textPosition(v_idx, this.X) = ...
                   graphStrcut.text_coordinates(v_idx,this.X);
               this.m_textPosition(v_idx, this.Y) = ...
                   graphStrcut.text_coordinates(v_idx,this.Y);
            end
        end
            
        function r = weights(this)
            r = this.m_weights;
        end
        
        function r = allVerticesPositions(this)
            r = this.m_vertexPosition;
        end
        
        function r = labeled_positive(this)
            assert( this.numLabels() == this.BINARY_NUM_LABELS);
            isPositive = this.m_correctLabels( :, this.positiveLabel() );
            r = find( isPositive ~= 0);
        end
        
        function r = labeled_negative(this)
            assert( this.numLabels() == this.BINARY_NUM_LABELS);
            isNegative = this.m_correctLabels( :, this.negativeLabel() );
            r = find( isNegative ~= 0);
        end
        
        function r = labeled(this)
            assert( this.numLabels() == this.BINARY_NUM_LABELS);
            r = [   this.labeled_positive(); 
                    this.labeled_negative() ];
        end
        
        function r = numLabels(this)
            r = size( this.m_correctLabels, 2 );
        end
        
        function r = positiveLabel(this)
            assert( this.numLabels() == this.BINARY_NUM_LABELS);
            r = 2; % positive label index
        end
        
        function r = negativeLabel(this)
            assert( this.numLabels() == this.BINARY_NUM_LABELS);
            r = 1; % negative label index
        end
        
        function setVertexLabel(this, v_idx, label_idx)
            newLabel = zeros( 1, this.numLabels() );
            newLabel( label_idx ) = 1;
            this.m_correctLabels(v_idx,:) = newLabel;
        end
        
        function clearLabels(this, v_idx )
            newLabel = zeros( 1, this.numLabels() );
            this.m_correctLabels(v_idx,:) = newLabel;
        end
        
        function R = addVertex(this, newVertexPosition)
            old_num_vertices = this.numVertices();
            newPosition = [ newVertexPosition.x newVertexPosition.y ];
            this.m_vertexPosition = [this.m_vertexPosition; newPosition];
            this.m_weights = [this.m_weights;
                        zeros(1,old_num_vertices)];
            this.m_weights = [this.m_weights  zeros(old_num_vertices+1,1)];
            this.m_correctLabels = [ this.m_correctLabels;
                               zeros(1,this.numLabels()) ];
            textPosition  = newPosition + [-0.02 0.02];
            this.m_textPosition = [this.m_textPosition;textPosition];
            newVertexID = old_num_vertices+1;
            this.m_vertexProperties(newVertexID).showText = 0;
            this.m_vertexProperties(newVertexID).name = [];
            this.m_vertexProperties(newVertexID).showArrow = 0;
            R = newVertexID;
        end
        
        function removeVertex( this, v_idx )
            this.m_vertexPosition(v_idx,:)=[];
            this.m_textPosition(v_idx,:)=[];
            this.m_vertexProperties(v_idx) = [];
            this.m_weights(v_idx,:)=[];
            this.m_weights(:,v_idx)=[];
            this.m_correctLabels(v_idx, :) = [];
        end
        
        function addEdge(this, v1_idx, v2_idx )
            weight = 1;
            this.setEdgeWeight( v1_idx, v2_idx, weight );
        end
        
        function removeEdge(this, v1_idx, v2_idx )
            weight = 0;
            this.setEdgeWeight( v1_idx, v2_idx, weight );
        end
        
        function R = getEdgeWeight( this, v1_idx, v2_idx )
            R = this.m_weights(v1_idx, v2_idx);
        end
        
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
        
        function moveVertex(this, v_idx, newPosition)
            this.m_vertexPosition(v_idx,this.X) = newPosition.x;
            this.m_vertexPosition(v_idx,this.Y) = newPosition.y;
        end
        
        function r = vertexPosition( this, v_idx )
            r = [this.m_vertexPosition(v_idx,this.X) ...
                 this.m_vertexPosition(v_idx,this.Y)];
        end
        
        function r = vertexTextPosition( this, v_idx )
            r = [this.m_textPosition(v_idx,this.X) ...
                 this.m_textPosition(v_idx,this.Y)];
        end
        
        function set_vertexTextPosition(this, v_idx, value)
            this.m_textPosition(v_idx,:) = value;
        end
        
        function set_vertexTextOffset(this, v_idx, value)
            pos = this.vertexTextPosition(v_idx);
            pos = pos + value;
            this.set_vertexTextPosition(v_idx, pos);
        end
        
        function r = isShowText(this, v_idx)
            r = this.m_vertexProperties(v_idx).showText;
        end
        
        function set_showText(this, v_idx, value)
            this.m_vertexProperties(v_idx).showText = value;
        end
        
        function r = isShowArrow(this, v_idx)
            r = this.m_vertexProperties(v_idx).showArrow;
        end
        
        function set_showArrow(this, v_idx, value)
            this.m_vertexProperties(v_idx).showArrow = value;
        end
        
        function set_vertexName(this, v_idx, value)
            this.m_vertexProperties(v_idx).name = value;
        end
        
        function r = vertexName(this,v_idx)
            r = this.m_vertexProperties(v_idx).name;
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

