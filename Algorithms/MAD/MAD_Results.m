classdef MAD_Results < handle
    %MAD_RESULTS Summary of this class goes here
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
                         zeros(1, this.numLabels()) ];
        end
        
        function remove_vertex(this, vertex_i)
            this.m_Y(vertex_i, :) = [];
        end
        
        function r = asText( this, vertex_i, ~)
            NEGATIVE = 1; POSITIVE = 2; DUMMY = 3;
            y = this.m_Y( vertex_i, : );
            r = sprintf('(%6.4f,%6.4f, %6.4f)', ...
                            y(NEGATIVE), y(POSITIVE), y(DUMMY) );
        end
        
        function r = allColors(this, ~)
            NEGATIVE = 1; POSITIVE = 2;
            r = 0.5 * (this.m_Y(:, NEGATIVE) + this.m_Y(:, POSITIVE));
        end
        
    end % (Access = public)
    
    methods (Access = private)
        function r = numLabels(this)
            r = size( this.m_Y, 2);
        end
    end % methods (Access = private)
    
end

