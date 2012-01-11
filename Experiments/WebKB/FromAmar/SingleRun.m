classdef SingleRun < handle
    %SINGLERUN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        labeledPositive;
        labeledNegative;
        correctLabels;
        positiveInitialValue;
        negativeInitialValue;
        classToLabelMap;
    end
    
    properties (Access = public)
        LP = 1;
        CSSL = 2;
        CSSLMC = 3;
        MAD = 4;
    end
    
    properties (Access=private)
        m_labeled;
        m_unlabeled_correct_labels;
        m_unlabeled_num_mistakes;
        
        m_LP_result;
        m_MAD_result;
        m_CSSL_result
        m_CSSLMC_result;
    end
    
    methods (Access=public)
        function this = SingleRun() % Constructor
            this.m_labeled = [];
            this.m_unlabeled_correct_labels = [];
            this.m_unlabeled_num_mistakes = zeros( this.numAlgorithms(),1 );
        end
        
        function set_results( this, R, algorithmType )
            if (algorithmType == this.LP)
                this.m_LP_result = R;
            elseif (algorithmType == this.MAD)
                this.m_MAD_result = R;
            elseif (algorithmType == this.CSSL)
                this.m_CSSL_result = R;
            elseif (algorithmType == this.CSSLMC)
                this.m_CSSLMC_result = R;
            end
        end
        
        function r = numAlgorithms(this)
            r = 4;
        end
       
        %% Return final mu for unlabeled vertices
                
        function r = unlabeled_binary_prediction(this, algorithmType)
            algorithmResults = this.getAlgorithmResults( algorithmType );
            
            r = algorithmResults.binaryPrediction();
            r( this.labeled() ) = [];
        end
        
        %% Return final confidence for unlabeled vertices
        
        function r = unlabeled_confidence(this, algorithmType)
            algorithmResults = this.getAlgorithmResults( algorithmType );
            
            r = algorithmResults.binaryPredictionConfidence();
            r( this.labeled() ) = [];
        end
        
        %% calculate margin for unlabeled vertices
        
        function r = unlabeled_margin(this, algorithmType)
            r = this.unlabeled_binary_prediction(algorithmType) .* ...
                    this.unlabeled_correct_labels();
        end
        
        %% get number of unlabeled vertices
        
        function r = numUnlabeledVertices(this)
            numVertices = length(this.correctLabels);
            numLabeled = length( this.labeled() );
            r = numVertices - numLabeled;
        end
        
        %% get result sorted by confidence
        
        function r = sorted_by_confidence( this, algorithmType )
            r = this.calsSortedByConfidence(algorithmType);
        end
        
        %% get number of mistakes (on unlabeled data) for pecific algorithm
        
        function r = unlabeled_num_mistakes(this, algorithmType)
            if (this.m_unlabeled_num_mistakes(algorithmType) == 0)
                prediction = this.unlabeled_binary_prediction( algorithmType );
                this.m_unlabeled_num_mistakes(algorithmType) = ...
                    this.unlabeled_num_mistakes_binary(prediction);
            end
            r = this.m_unlabeled_num_mistakes(algorithmType) ;
        end
        
        %% calculate correct vertices for unlabeled vertices
        %  (for all algorithms this is the same)
        
        function r = unlabeled_correct_labels(this)
            if isempty( this.m_unlabeled_correct_labels )
                this.m_unlabeled_correct_labels = this.correctLabels;
                this.m_unlabeled_correct_labels( this.labeled() ) = [];
            end
            r = this.m_unlabeled_correct_labels;
        end
        
    end % (Access=public)
    
    methods (Access = private)
        
        %% Return indices for labeled vertices
        
        function r = labeled(this)
            if isempty( this.m_labeled )
                this.m_labeled  = ...
                    [this.labeledPositive;
                     this.labeledNegative];
            end
            r = this.m_labeled ;
        end
        
        %% Calculate unlabeled prediction from unlabeled final mu
        
%         function calc_unlabeled_prediction(this)
%             numClasses = size( this.classToLabelMap, 1);
%             range = linspace(this.negativeInitialValue, ...
%                              this.positiveInitialValue, numClasses + 1);
% 
%             prediction = this.unlabeled_final_mu() ;
%             classValueMap = [-1; +1];
%             for range_i = 1:numClasses
%                 bottom = range(range_i);
%                 top = range(range_i + 1);
%                 prediction(bottom <= prediction & prediction < top) = ...
%                     classValueMap(range_i);
%             end
%             this.m_unlabeled_prediction = prediction;
%         end
        
        %% Calculate if prediction for unlabeled is correct
        
        function r = unlabeled_num_mistakes_binary(this, binaryPrediction)
            isCorrect = this.unlabeled_is_correct_binary( binaryPrediction );
            isWrong    = 1 - isCorrect;
            r = sum(isWrong);
        end
        
        %% calculate if a binary prediction on unlabeled data is correct
        
        function r = unlabeled_is_correct_binary(this, binaryPrediction)
            r = ( sign(binaryPrediction) == this.unlabeled_correct_labels() );
        end
        
        %% calculate confidence, margin, accumulative loss, correct and
        %  wrong vectors according to sorted confidence
        
        function r = calsSortedByConfidence(this, algorithmType)
            [values,indices] = sort( this.unlabeled_confidence(algorithmType) );

            binaryPrediction = this.unlabeled_binary_prediction(algorithmType);
            isCorrect        = this.unlabeled_is_correct_binary(binaryPrediction);
            margin           = this.unlabeled_margin(algorithmType);
            
            sorted.by_confidence.confidence = values;
            sorted.by_confidence.correct = isCorrect(indices);
            sorted.by_confidence.wrong = ...
                1 - sorted.by_confidence.correct;
            sorted.by_confidence.margin = margin( indices );
            sorted.by_confidence.accumulative = ...
                cumsum(sorted.by_confidence.wrong);

            r = sorted.by_confidence;
        end
        
        %% get a specific algorithm results object
        
        function r = getAlgorithmResults(this, algorithmType)
            if (algorithmType == this.LP)
                r = this.m_LP_result;
            elseif (algorithmType == this.MAD)
                r = this.m_MAD_result;
            elseif (algorithmType == this.CSSL)
                r = this.m_CSSL_result;
            elseif (algorithmType == this.CSSLMC)
                r = this.m_CSSLMC_result;
            end
        end

    end % (Access = private)
end