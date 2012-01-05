classdef CSSL_Result < handle
    %CSSL_RESULT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        m_mu;
        m_v;
    end % (Access = private)
    
    methods (Access = public)
        
        function set_results(this, resultSource)
            this.m_mu = resultSource.mu;
            this.m_v  = resultSource.v;
        end
        
        function add_vertex(this)
            this.m_mu = [ this.m_mu;
                          zeros(1, this.numIterations()) ];
            this.m_v  = [ this.m_v;
                          ones(1, this.numIterations()) ];
        end
        
        function remove_vertex(this, vertex_i)
            this.m_mu(vertex_i,:) = [];
            this.m_v (vertex_i,:) = [];
        end
        
        function r = asText( this, vertex_i, iteration_i)
            mu = this.m_mu( vertex_i, iteration_i );
            v  = this.m_v ( vertex_i, iteration_i );
            
            r = sprintf('(%6.4f,%6.4f)', mu, v);
        end
        
        function r = allColors(this, iteration_i)
            r = this.m_mu(:, iteration_i);
        end
    end % (Access = public)
    
    methods (Access = private)
        function r = numIterations(this)
            r = size( this.m_mu, 2);
        end
    end
    
end

