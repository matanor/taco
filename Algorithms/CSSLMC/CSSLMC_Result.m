classdef CSSLMC_Result < SSLMC_Result
    %CSSLMC_Result Confidence Semi-Supervised Learning Multi-Class result
    %   Detailed explanation goes here
    
    properties (Access = public)
        m_v;         % confidence on nodes
        m_edges_v;   % confidence on edges
        m_vertexToEdgeMap; % vertexToEdgeMap(i,j) gives the index of
                           % the edge between v_i and v_j, make the map symmetric.
        m_keepSecondOrderInResults;
    end % (Access = private)
    
    methods (Access = public)
        
        %% clearOutput
    
        function clearOutput(this)
            clearOutput@SSLMC_Result(this);
            this.m_v        = [];
            this.m_edges_v  = [];
            this.m_vertexToEdgeMap = [];
            this.m_keepSecondOrderInResults = 0;
        end
    
        %% set_results
        
        function set_results(this, resultSource, saveAllIterations)
            this.m_numIterations = SSLMC_Result.calcNumIterations( resultSource.mu );
            if saveAllIterations
                this.m_Y        = resultSource.mu;
                this.m_v        = resultSource.v;
                if this.m_keepSecondOrderInResults && isfield( resultSource, 'edges_v' )
                    this.m_edges_v  = resultSource.edges_v;
                end
            else
                this.m_Y        = resultSource.mu       (:,:,end);
                this.m_v        = resultSource.v        (:,:,end);
                if this.m_keepSecondOrderInResults && isfield( resultSource, 'edges_v' )
                    this.m_edges_v  = resultSource.edges_v  (:,:,end);
                end
            end
            if this.m_keepSecondOrderInResults && isfield( resultSource, 'vertexToEdgeMap' )
                this.m_vertexToEdgeMap = resultSource.vertexToEdgeMap;
            end
        end
        
        %% add_vertex
        
        function add_vertex(this)
            this.m_Y = SSLMC_Result.addVertexToMatrix( this.m_Y );
            this.m_v = SSLMC_Result.addVertexToMatrix( this.m_v );
        end
        
        %% remove_vertex
        
        function remove_vertex(this, vertex_i)
            this.m_Y(vertex_i,:,:) = [];
            this.m_v(vertex_i,:,:) = [];
        end
        
        %% asText
        
        function r = asText( this, vertex_i, iteration_i)
            mu.positive = this.m_Y( vertex_i, this.POSITIVE, iteration_i );
            mu.negative = this.m_Y( vertex_i, this.NEGATIVE, iteration_i );
            
            num_uncertainty_values_per_node = size(this.m_v, 2);
            if num_uncertainty_values_per_node > 1
                v.positive  = this.m_v( vertex_i, this.POSITIVE, iteration_i );
                v.negative  = this.m_v( vertex_i, this.NEGATIVE, iteration_i );
            else
                v.positive  = this.m_v( vertex_i, 1, iteration_i );
                v.negative  = v.positive;
            end
            
            r = sprintf('(%6.4f,%6.4f)\n(%6.4f,%6.4f)', ...
                    mu.positive, v.positive, mu.negative, v.negative);
        end
        
        %% edgeText
         
        function r = edgeText(this, start_vertex, end_vertex, iteration_i)
            edgeIndex      = this.m_vertexToEdgeMap(start_vertex, end_vertex);
            num_classes = size(this.m_edges_v, 2);
            if num_classes > 1
                edgeConfidence.positive = this.m_edges_v(edgeIndex, this.POSITIVE, iteration_i);
                edgeConfidence.negative = this.m_edges_v(edgeIndex, this.NEGATIVE, iteration_i);
                r = sprintf('(%6.4f,%6.4f)\n', ...
                    edgeConfidence.positive, edgeConfidence.negative);
            else
                edgeConfidence = this.m_edges_v(edgeIndex, 1, iteration_i);
                r = sprintf('(%6.4f)\n', edgeConfidence);
            end                
        end
        
        %% allColors 
        
        function r = allColors(this, iteration_i)
            r = 0.5 * ( (-1) * this.m_Y(:, this.NEGATIVE, iteration_i) + ...
                               this.m_Y(:, this.POSITIVE, iteration_i));
        end
        
        %% legend
        
        function r = legend(~)
            r = '(mu,v) (+1) \newline(mu,v) (-1)';
        end

        %% getConfidence
        
        function r = getConfidence( this, vertex_i, class_i)
            confidenceMatrix = this.m_v(:,:,end);
            r = confidenceMatrix( vertex_i, class_i );
        end
        
    end % (Access = public)
    
end

