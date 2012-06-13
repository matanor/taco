classdef AM_Result < SSLMC_Result
    %AM_Result Alternating Minimization Semi-Supervised Learning Multi-Class result
    %   Detailed explanation goes here
    
    properties (Access = public)
        m_q;
    end % (Access = private)
    
    methods (Access = public)
        
        %% clearOutput
    
        function clearOutput(this)
            clearOutput@SSLMC_Result(this);
            this.m_q = [];
        end
        
        %% set_results
        
        function set_results(this, resultSource, saveAllIterations)
            this.m_numIterations = SSLMC_Result.calcNumIterations( resultSource.p );
            if saveAllIterations
                this.m_Y = resultSource.p;
                this.m_q = resultSource.q;
            else
                this.m_Y = resultSource.p(:,:,end);
                this.m_q = resultSource.q(:,:,end);
            end
        end
        
        %% add_vertex
        
        function add_vertex(this)
            this.m_Y = SSLMC_Result.addVertexToMatrix( this.m_Y );
            this.m_q = SSLMC_Result.addVertexToMatrix( this.m_q );
        end
        
        %% remove_vertex
        
        function remove_vertex(this, vertex_i)
            this.m_Y(vertex_i,:,:) = [];
            this.m_q(vertex_i,:,:) = [];
        end
        
        %% asText
        
        function r = asText( this, vertex_i, iteration_i)
            p.positive = this.m_Y( vertex_i, this.POSITIVE, iteration_i );
            p.negative = this.m_Y( vertex_i, this.NEGATIVE, iteration_i );
            
            r = sprintf('(%6.4f,%6.4f)', ...
                p.positive, p.negative);
        end
        
        %% allColors
        
        function r = allColors(this, iteration_i)
            r = 0.5 * ( (-1) * this.m_Y(:, this.NEGATIVE, iteration_i) + ...
                               this.m_Y(:, this.POSITIVE, iteration_i));
        end
        
        %% legend
        
        function r = legend(~)
            r = '(+1,-1)';
        end
        
    end % (Access = public)
    
end

