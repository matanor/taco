classdef MAD_Results < handle
    %MAD_RESULTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        m_Y; % vertices X labels X iterations
        m_probabilities;
    end % (Access = private)
    
    properties (Access = private)
        BINARY_NUM_LABELS;
        NEGATIVE; 
        POSITIVE; 
        DUMMY;
    end % (Access = private)
    
    methods (Access = public)

        function this = MAD_Results() % Constructor
            this.BINARY_NUM_LABELS = 2;
            this.NEGATIVE = 1;
            this.POSITIVE = 2;
            this.DUMMY = 3;
        end
        
        function set_results(this, resultSource)
            this.m_Y             = resultSource.Y;
            this.m_probabilities = resultSource.p;
        end
        
        function add_vertex(this)
            new_m_Y = zeros( size(this.m_Y,1) + 1, ...
                             size(this.m_Y,2), ...
                             size(this.m_Y,3) );
            for iter_i=1:this.numIterations()
                new_m_Y(:,:,iter_i) = [ this.m_Y(:,:,iter_i);
                                         zeros(1, this.numLabels()) ];
            end
            this.m_Y = new_m_Y;
            this.m_probabilities.inject   = [ this.m_probabilities.inject;
                                            0 ];
            this.m_probabilities.continue = [ this.m_probabilities.continue;
                                            0 ];
            this.m_probabilities.abandon  = [ this.m_probabilities.abandon;
                                            0 ];
        end
        
        function remove_vertex(this, vertex_i)
            this.m_Y(vertex_i, :, :) = [];
        end
        
        function r = asText( this, vertex_i, iteration_i)
            y = this.m_Y( vertex_i, :, iteration_i );
            p_inject   = this.m_probabilities.inject(vertex_i); 
            p_continue = this.m_probabilities.continue(vertex_i);
            p_abandon  = this.m_probabilities.abandon(vertex_i); 

            r = sprintf('(%6.4f,%6.4f, %6.4f)\n(%6.4f,%6.4f, %6.4f)', ...
                        p_inject, p_continue, p_abandon,...
                        y(this.NEGATIVE), y(this.POSITIVE), y(this.DUMMY) );
        end
        
        function r = allColors(this, iter_i)
            r = 0.5 * ( (-1) * this.m_Y(:, this.NEGATIVE, iter_i) + ...
                               this.m_Y(:, this.POSITIVE, iter_i));
        end
        
        function r = legend(~)
            r = ['(p\_inject,p\_continue, p\_abandon)\newline' ... 
                 '(y(NEGATIVE), y(POSITIVE), y(DUMMY))' ];
        end
        
        function r = numIterations(this)
            r = size( this.m_Y, 3);
        end
        
        function r = binaryPrediction(this)
            assert( this.numLabels() == (this.BINARY_NUM_LABELS + 1) );
            final_Y = this.m_Y(:,:,end);
            final_Y(:,this.DUMMY) = [];
            [~,indices] = max(final_Y,[],2);
            final_Y(:,this.NEGATIVE) = -final_Y(:,this.NEGATIVE);
            prediction = zeros(this.numVertices(), 1);
            for pred_i=1:length(prediction)
                prediction( pred_i ) = final_Y( pred_i, indices(pred_i) );
            end
            r = prediction;
        end
        
    end % (Access = public)
    
    methods (Access = private)
        function r = numLabels(this)
            r = size( this.m_Y, 2);
        end
        
        function r = numVertices(this)
            r = size( this.m_Y, 1);
        end
       
    end % methods (Access = private)
    
end

