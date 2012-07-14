classdef MAD_Results < SSLMC_Result
    %MAD_RESULTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        m_probabilities;
    end % (Access = private)
    
    properties (Access = private)
        DUMMY;
    end % (Access = private)
    
    methods (Access = public)

        %% Constructor
        
        function this = MAD_Results() % Constructor
            this.DUMMY = 3;
        end
        
        %% clearOutput
    
        function clearOutput(this)
            Logger.log('MAD_Results::clearOutput.');
            clearOutput@SSLMC_Result(this);
            this.m_probabilities = [];
        end
        
        %% set_results
        
        function set_results(this, resultSource, saveAllIterations)
            this.m_numIterations = ...
                SSLMC_Result.calcNumIterations( resultSource.Y );
            if saveAllIterations%ParamsManager.SAVE_ALL_ITERATIONS_IN_RESULT
                this.m_Y = resultSource.Y;
            else
                this.m_Y = resultSource.Y(:,:,end);
            end
            this.m_probabilities = resultSource.p;
        end
        
        %% add_vertex
        
        function add_vertex(this)
            new_m_Y = zeros( size(this.m_Y,1) + 1, ...
                             size(this.m_Y,2), ...
                             size(this.m_Y,3) );
            for iter_i=1:this.numIterations()
                new_m_Y(:,:,iter_i) = [ this.m_Y(:,:,iter_i);
                                         zeros(1, this.numLabelsIncludingDummy()) ];
            end
            this.m_Y = new_m_Y;
            this.m_probabilities.inject   = [ this.m_probabilities.inject;
                                            0 ];
            this.m_probabilities.continue = [ this.m_probabilities.continue;
                                            0 ];
            this.m_probabilities.abandon  = [ this.m_probabilities.abandon;
                                            0 ];
        end
        
        %% remove_vertex
        
        function remove_vertex(this, vertex_i)
            this.m_Y(vertex_i, :, :) = [];
        end
        
        %% asText
        
        function r = asText( this, vertex_i, iteration_i)
            y = this.m_Y( vertex_i, :, iteration_i );
            p_inject   = this.m_probabilities.inject(vertex_i); 
            p_continue = this.m_probabilities.continue(vertex_i);
            p_abandon  = this.m_probabilities.abandon(vertex_i); 

            r = sprintf('(%6.4f,%6.4f, %6.4f)\n(%6.4f,%6.4f, %6.4f)', ...
                        p_inject, p_continue, p_abandon,...
                        y(this.NEGATIVE), y(this.POSITIVE), y(this.DUMMY) );
        end
        
        %% allColors
        
        function r = allColors(this, iter_i)
            r = 0.5 * ( (-1) * this.m_Y(:, this.NEGATIVE, iter_i) + ...
                               this.m_Y(:, this.POSITIVE, iter_i));
        end
        
        %% legend
        
        function r = legend(~)
            r = ['(p\_inject,p\_continue, p\_abandon)\newline' ... 
                 '(y(NEGATIVE), y(POSITIVE), y(DUMMY))' ];
        end
        
        %% getFinalScoreMatrix
        
        function r = getFinalScoreMatrix(this)
%             Logger.log('MAD::getFinalPredictionMatrix');
            r = this.m_Y(:,:,end);
            r(:,end) = [];
        end
        
        %% probabilities
        
        function r = probabilities(this)
            r = this.m_probabilities;
        end
        
        %% numLabelsIncludingDummy
        
        function r = numLabelsIncludingDummy(this)
            r = this.numLabels();
            r = r + 1;
        end
        
    end % (Access = public)
    
end

