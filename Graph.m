classdef Graph < handle
    %GRAPH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        m_W;
        m_correctLabels;
        m_vertexPosition;
        m_labels;
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
            this.m_W = graphStrcut.W;
            numVertices = this.numVertices();
            this.m_labels         = zeros(numVertices, this.BINARY_NUM_LABELS);
            this.m_vertexPosition = zeros(numVertices, 2);
           
            positive = graphStrcut.labeled.positive;
            negative = graphStrcut.labeled.negative;
           
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
            end
        end
            
        function r = weights(this)
            r = this.m_W;
        end
        
        function r = allVerticesPositions(this)
            r = this.m_vertexPosition;
        end
        
        function r = labeled_positive(this)
            assert( this.numLabels() == this.BINARY_NUM_LABELS);
            isPositive = this.m_labels( :, this.positiveLabel() );
            r = find( isPositive ~= 0);
        end
        
        function r = labeled_negative(this)
            assert( this.numLabels() == this.BINARY_NUM_LABELS);
            isNegative = this.m_labels( :, this.negativeLabel() );
            r = find( isNegative ~= 0);
        end
        
        function r = labeled(this)
            assert( this.numLabels() == this.BINARY_NUM_LABELS);
            r = [   this.labeled_positive(); 
                    this.labeled_negative() ];
        end
        
        function r = numVertices(this)
            assert( size(this.m_W,1) == size(this.m_W,2) );
            r = size(this.m_W, 1);
        end
        
        function r = numLabels(this)
            r = size( this.m_labels, 2 );
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
            this.m_labels(v_idx,:) = newLabel;
        end
        
        function clearLabels(this, v_idx )
            newLabel = zeros( 1, this.numLabels() );
            this.m_labels(v_idx,:) = newLabel;
        end
        
        function addVertex(this, newVertexPosition)
            old_num_vertices = this.numVertices();
            newPosition = [ newVertexPosition.x newVertexPosition.y ];
            this.m_vertexPosition = [this.m_vertexPosition; newPosition];
            this.m_W = [this.m_W;
                        zeros(1,old_num_vertices)];
            this.m_W = [this.m_W  zeros(old_num_vertices+1,1)];
            this.m_labels = [ this.m_labels;
                               zeros(1,this.numLabels()) ];
        end
        
        function removeVertex( this, v_idx )
            this.m_vertexPosition(v_idx,:)=[];
            this.m_W(v_idx,:)=[];
            this.m_W(:,v_idx)=[];
            this.m_labels(v_idx, :) = [];
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
            R = this.m_W(v1_idx, v2_idx);
        end
        
        function setEdgeWeight(this, v1_idx, v2_idx, weight )
            Logger.log([  'Setting edge between vertices ' ...
                    num2str(v1_idx) ' ' num2str(v2_idx) ...
                    ' to weight = ' num2str(weight) ]);
            if (v1_idx == v2_idx)
                Logger.log('Single node edge, skipping');
                return ;
            end
            this.m_W(v1_idx, v2_idx) = weight;
            this.m_W(v2_idx, v1_idx) = weight;
        end
        
        function moveVertex(this, v_idx, newPosition)
            this.m_vertexPosition(v_idx,this.X) = newPosition.x;
            this.m_vertexPosition(v_idx,this.Y) = newPosition.y;
        end
        
        function r = vertexPosition( this, v_idx )
            r = [this.m_vertexPosition(v_idx,this.X) ...
                 this.m_vertexPosition(v_idx,this.Y)];
        end

    end % methods (Access = public)

    methods ( Static )
        function saveStruct(graph,fileName)
            save(fileName, 'graph' );
        end
    end
    methods (Access = private)
        
        function r = asStruct(this)
            r.W = this.m_W;
            r.labeled.positive = this.labeled_positive();
            r.labeled.negative = this.labeled_negative();
            r.v_coordinates = this.m_vertexPosition;
        end
    end % methods (Access = private)
    
end

