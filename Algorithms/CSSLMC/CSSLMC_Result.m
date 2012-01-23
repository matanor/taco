classdef CSSLMC_Result < SSLMC_Result
    %CSSLMC_Result Confidence Semi-Supervised Learning Multi-Class result
    %   Detailed explanation goes here
    
    properties (Access = public)
        m_v; % confidence
    end % (Access = private)
    
    methods (Access = public)
        
        function set_results(this, resultSource)
            this.m_Y = resultSource.mu;
            this.m_v = resultSource.v;
        end
        
        function add_vertex(this)
            this.m_Y = CSSLMC_Result.addVertexToMatrix( this.m_Y );
            this.m_v = CSSLMC_Result.addVertexToMatrix( this.m_v );
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
        
        function r = numIterations(this)
            r = SSLMC_Result.calcNumIterations( this.m_Y );
        end
        
        function r = binaryPredictionConfidence(this)
            assert( this.numLabels() == (this.BINARY_NUM_LABELS) );
            final_mu = this.m_Y(:,:,end);
            [~,indices] = max(final_mu,[],2);
            final_v = this.m_v(:,:,end);
            confidence = zeros(this.numVertices(), 1);
            for vertex_i=1:length(confidence)
                confidence( vertex_i ) = final_v( vertex_i, indices(vertex_i) );
            end
            r = confidence;
        end
        
    end % (Access = public)
    
    methods (Static)
        function Mout = addVertexToMatrix( M )
            Mout = zeros( size(M,1) + 1, size(M,2), size(M,3) );
            numIterations = SSLMC_Result.calcNumIterations( M );
            numLabels     = SSLMC_Result.calcNumLabels(M);
            for iter_i=1:numIterations
                Mout(:,:,iter_i) = [ M(:,:,iter_i);
                                     zeros(1, numLabels) ];
            end
        end

    end % (Static)
    
end

