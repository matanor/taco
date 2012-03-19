classdef CSSLMC_Result < SSLMC_Result
    %CSSLMC_Result Confidence Semi-Supervised Learning Multi-Class result
    %   Detailed explanation goes here
    
    properties (Access = public)
        m_v; % confidence
    end % (Access = private)
    
    methods (Access = public)
        
        function set_results(this, resultSource, saveAllIterations)
            this.m_numIterations = SSLMC_Result.calcNumIterations( resultSource.mu );
            if saveAllIterations
                this.m_Y = resultSource.mu;
                this.m_v = resultSource.v;
            else
                this.m_Y = resultSource.mu(:,:,end);
                this.m_v = resultSource.v(:,:,end);
            end
        end
        
        function add_vertex(this)
            this.m_Y = SSLMC_Result.addVertexToMatrix( this.m_Y );
            this.m_v = SSLMC_Result.addVertexToMatrix( this.m_v );
        end
        
        function remove_vertex(this, vertex_i)
            this.m_Y(vertex_i,:,:) = [];
            this.m_v(vertex_i,:,:) = [];
        end
        
        function r = asText( this, vertex_i, iteration_i)
            mu.positive = this.m_Y( vertex_i, this.POSITIVE, iteration_i );
            v.positive  = this.m_v( vertex_i, this.POSITIVE, iteration_i );
            mu.negative = this.m_Y( vertex_i, this.NEGATIVE, iteration_i );
            v.negative  = this.m_v( vertex_i, this.NEGATIVE, iteration_i );
            
            r = sprintf('(%6.4f,%6.4f)\n(%6.4f,%6.4f)', ...
                mu.positive, v.positive, mu.negative, v.negative);
        end
        
        function r = allColors(this, iteration_i)
            r = 0.5 * ( (-1) * this.m_Y(:, this.NEGATIVE, iteration_i) + ...
                               this.m_Y(:, this.POSITIVE, iteration_i));
        end
        
        function r = legend(~)
            r = '(mu,v) (+1) \newline(mu,v) (-1)';
        end

        function r = getConfidence( this, vertex_i, class_i)
            confidenceMatrix = this.m_v(:,:,end);
            r = confidenceMatrix( vertex_i, class_i );
        end
        
    end % (Access = public)
    
end

