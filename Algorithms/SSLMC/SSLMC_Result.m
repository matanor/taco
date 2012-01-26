classdef SSLMC_Result < handle
% Base class SSL multi-class (MC) algorithms result

    properties (Access=public)
        m_Y; % vertices X labels X iterations
    end
    
	properties (Access = protected)
        BINARY_NUM_LABELS;
        NEGATIVE; 
        POSITIVE; 
    end % (Access = protected)
    
    methods (Access = public )
        
        function this = SSLMC_Result() % Constructor
            this.BINARY_NUM_LABELS = 2;
            this.NEGATIVE = 1;
            this.POSITIVE = 2;
        end
        
        function r = prediction(this)
            scoreMatrix = this.getFinalScoreMatrix();
            [~,indices] = max(scoreMatrix,[],2);
            r = indices;
        end
        
%         function r = scoreForLabel(this, label_i)
%             scores = this.getFinalScoreMatrix();
%             r = scores(:, label_i);
%         end
        
        function r = getFinalScoreMatrix(this)
%             disp('SSLMC::getFinalScoreMatrix');
            r = this.m_Y(:,:,end);
        end

        function r = bestScore(this)
            scoreMatrix = this.getFinalScoreMatrix();
            [~,indices] = max(scoreMatrix,[],2);
            bestScore = zeros(this.numVertices(), 1);
            for vertex_i=1:length(bestScore)
                bestScore( vertex_i ) = scoreMatrix( vertex_i, indices(vertex_i) );
            end
            r = bestScore;
        end
        
        function r = binaryPrediction(this)
            assert( this.numLabels() == (this.BINARY_NUM_LABELS) );
            scoreMatrix = this.getFinalScoreMatrix();
            [~,indices] = max(scoreMatrix,[],2);
            scoreMatrix(:,this.NEGATIVE) = -scoreMatrix(:,this.NEGATIVE);
            prediction = zeros(this.numVertices(), 1);
            for vertex_i=1:length(prediction)
                prediction( vertex_i ) = scoreMatrix( vertex_i, indices(vertex_i) );
            end
            r = prediction;
        end
        
        function r = numVertices(this)
            r = SSLMC_Result.calcVertices(this.m_Y);
        end
        
        function r = numIterations(this)
            r = SSLMC_Result.calcNumIterations(this.m_Y);
        end
        
        function r = numLabels(this)
            r = SSLMC_Result.calcNumLabels( this.getFinalScoreMatrix() );
        end
        
    end % methods (Access = public )
    
    methods (Static)
        
        function r = calcVertices( M )
                r = size( M, 1 );
        end
        
        function r = calcNumLabels( M )
            r = size( M, 2 );
        end
        
        function r = calcNumIterations( M )
            r = size( M, 3);
        end     

    end % methods ((Static))
end