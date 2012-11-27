classdef QC_Result < SSLMC_Result
    %QC_Result Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Access = public)

        %% set_results
        
        function set_results(this, resultSource, saveAllIterations)
            this.m_numIterations = ...
                SSLMC_Result.calcNumIterations( resultSource.mu );
            if saveAllIterations%ParamsManager.SAVE_ALL_ITERATIONS_IN_RESULT
                this.m_Y = resultSource.mu;
            else
                this.m_Y = resultSource.mu(:,:,end);
            end
        end
        
        %% add_vertex
        
        function add_vertex(this)
            this.m_Y = SSLMC_Result.addVertexToMatrix( this.m_Y );
        end
        
        %% remove_vertex
        
        function remove_vertex(this, vertex_i)
            this.m_Y(vertex_i,:,:) = [];
        end
        
        %% asText
        
        function r = asText( this, vertex_i, iteration_i)
            mu.positive = this.m_Y( vertex_i, this.POSITIVE, iteration_i );
            mu.negative = this.m_Y( vertex_i, this.NEGATIVE, iteration_i );

            r = sprintf('(%6.4f,%6.4f)', ...
                    mu.positive, mu.negative);
        end
        
        %% allColors
        
        function r = allColors(this, iter_i)
            r = 0.5 * ( (-1) * this.m_Y(:, this.NEGATIVE, iter_i) + ...
                               this.m_Y(:, this.POSITIVE, iter_i));
        end
        
        %% legend
        
        function r = legend(~)
            r = '(yNEGATIVE), y(POSITIVE)';
        end
        
    end % (Access = public)
    
end

