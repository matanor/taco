classdef CSSLMC_Result < handle
    %CSSLMC_Result Confidence Semi-Supervised Learning Multi-Class result
    %   Detailed explanation goes here
    
    properties (Access = private)
        m_mu;
        m_v;
    end % (Access = private)
    
	properties (Access = private)
        NEGATIVE; 
        POSITIVE; 
    end % (Access = private)
    
    methods (Access = public)
        
        function this = CSSLMC_Result() % Constructor
            this.NEGATIVE = 1;
            this.POSITIVE = 2;
        end
        
        function set_results(this, resultSource)
            this.m_mu = resultSource.mu;
            this.m_v  = resultSource.v;
        end
        
        function add_vertex(this)
            this.m_mu = CSSLMC_Result.addVertexToMatrix( this.m_mu );
            this.m_v  = CSSLMC_Result.addVertexToMatrix( this.m_v );
        end
        
        function remove_vertex(this, vertex_i)
            this.m_mu(vertex_i,:,:) = [];
            this.m_v (vertex_i,:,:) = [];
        end
        
        function r = asText( this, vertex_i, iteration_i)
            mu.positive = this.m_mu( vertex_i, this.POSITIVE, iteration_i );
            v.positive  = this.m_v ( vertex_i, this.POSITIVE, iteration_i );
            mu.negative = this.m_mu( vertex_i, this.NEGATIVE, iteration_i );
            v.negative  = this.m_v ( vertex_i, this.NEGATIVE, iteration_i );
            
            r = sprintf('(%6.4f,%6.4f)\n(%6.4f,%6.4f)', ...
                mu.positive, v.positive, mu.negative, v.negative);
        end
        
        function r = allColors(this, iteration_i)
            r = 0.5 * ( (-1) * this.m_mu(:, this.NEGATIVE, iteration_i) + ...
                               this.m_mu(:, this.POSITIVE, iteration_i));
        end
        
        function r = legend(~)
            r = '(mu,v) (+1) \newline(mu,v) (-1)';
        end
        
        function r = numIterations(this)
            r = CSSLMC.calcNumIterations( this.m_mu );
        end
        
    end % (Access = public)
    
    methods (Static)
        function Mout = addVertexToMatrix( M )
            Mout = zeros( size(M,1) + 1, size(M,2), size(M,3) );
            numIterations = CSSLMC_Result.calcNumIterations( M );
            numLabels = CSSLMC_Result.calcNumLabels(M);
            for iter_i=1:numIterations
                Mout(:,:,iter_i) = [ M(:,:,iter_i);
                                     zeros(1, numLabels) ];
            end
        end
        
        function r = calcNumIterations( M )
            r = size( M, 3);
        end
        
        function r = calcNumLabels( M )
            r = size( M, 2 );
        end
    end % (Static)
    
end

