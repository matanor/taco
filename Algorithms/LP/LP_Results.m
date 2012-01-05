classdef LP_Results < handle
    %LP_RESULTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        m_Y;
    end % (Access = private)
    
    methods (Access = public)
        
        function set_results(this, resultSource)
            this.m_Y = resultSource;
        end
        
        function add_vertex(this)
            this.m_Y = [ this.m_Y;
                         0 ];
        end
        
        function remove_vertex(this, vertex_i)
            this.m_Y(vertex_i) = [];
        end
        
        function r = asText( this, vertex_i, ~)
            y = this.m_Y( vertex_i );
            
            r = sprintf('(%6.4f)', y);
        end
        
        function r = allColors(this, ~)
            r = this.m_Y;
        end
        
    end % (Access = public)
    
end

