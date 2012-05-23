classdef SSLMC_Result < handle
% Base class SSL multi-class (MC) algorithms result

properties (Access=public)
    m_Y; % vertices X labels X iterations
    m_params;
    m_numIterations; % number of iterations that the algorithm had run
end

properties (Access = protected)
    BINARY_NUM_LABELS;
    NEGATIVE; 
    POSITIVE; 
end % (Access = protected)

methods (Access = public )

    %% Constructor
    
    function this = SSLMC_Result() 
        this.BINARY_NUM_LABELS = 2;
        this.NEGATIVE = 1;
        this.POSITIVE = 2;
    end
    
    %% clearOutput
    
    function clearOutput(this)
        this.m_Y = [];
    end
    
    %% getParams
    function R = getParams(this)
        R = this.m_params;
    end    
    
    %% set_params
    
    function set_params(this, value)
        this.m_params = value;
    end

    %% prediction
    
    function r = prediction(this)
        scoreMatrix = this.getFinalScoreMatrix();
        [~,indices] = max(scoreMatrix,[],2);
        r = indices;
    end

    %% predictionConfidence
    
    function r = predictionConfidence(this)
        scoreMatrix = this.getFinalScoreMatrix();
        [~,indices] = max(scoreMatrix,[],2);
        confidence = zeros(this.numVertices(), 1);
        for vertex_i=1:length(confidence)
            predictedClass = indices(vertex_i);
            confidence( vertex_i ) = this.getConfidence( vertex_i, predictedClass );
        end
        r = confidence;
    end

    %% 
    
    function r = this.getConfidence( this, ~, ~)
        r = 1;
    end

%         function r = scoreForLabel(this, label_i)
%             scores = this.getFinalScoreMatrix();
%             r = scores(:, label_i);
%         end


    %% getFinalScoreMatrix
    
    function r = getFinalScoreMatrix(this)
%             Logger.log('SSLMC::getFinalScoreMatrix');
        r = this.m_Y(:,:,end);
    end

    %% bestScore
    
    function r = bestScore(this)
        scoreMatrix = this.getFinalScoreMatrix();
        [~,indices] = max(scoreMatrix,[],2);
        bestScore = zeros(this.numVertices(), 1);
        for vertex_i=1:length(bestScore)
            bestScore( vertex_i ) = scoreMatrix( vertex_i, indices(vertex_i) );
        end
        r = bestScore;
    end

    %% binaryPrediction
    
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

    %% numVertices
    
    function r = numVertices(this)
        r = SSLMC_Result.calcVertices(this.m_Y);
    end

    %% numIterations
    
    function r = numIterations(this)
        r = this.m_numIterations;
    end

    %% numLabels
    
    function r = numLabels(this)
        r = SSLMC_Result.calcNumLabels( this.getFinalScoreMatrix() );
    end

end % methods (Access = public )

methods (Static)
    %% calcVertices
    
    function r = calcVertices( M )
            r = size( M, 1 );
    end
    
    %% calcNumLabels

    function r = calcNumLabels( M )
        r = size( M, 2 );
    end

    %% calcNumIterations
    
    function r = calcNumIterations( M )
        r = size( M, 3);
    end     

    %% addVertexToMatrix
    
	function Mout = addVertexToMatrix( M )
        Mout = zeros( size(M,1) + 1, size(M,2), size(M,3) );
        numIterations = SSLMC_Result.calcNumIterations( M );
        numLabels     = SSLMC_Result.calcNumLabels(M);
        for iter_i=1:numIterations
            Mout(:,:,iter_i) = [ M(:,:,iter_i);
                                 zeros(1, numLabels) ];
        end
    end

end % methods ((Static))
end