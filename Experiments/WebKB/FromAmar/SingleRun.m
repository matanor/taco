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
        %result;
        %LP;     % results from Label Prpagation algorithm
    end
    
    properties (Access = public)
        LP = 1;
        CSSL = 2;
        CSSLMC = 3;
        MAD = 4;
    end
    
    properties (Access=private)
        m_labeled;
        m_unlabeled_final_mu;
        m_unlabeled_final_confidence;
        m_unlabeled_prediction;
        m_unlabeled_correct_labels;
        m_unlabeled_margin;
        m_unlabeled_is_correct;
        m_unlabeled_sorted;
        m_unlabeled_correct_label;

        m_unlabeled_num_mistakes;
%         m_unlabeled_num_mistakes_LP;
%         m_unlabeled_num_mistakes_CSSL;
%         m_unlabeled_num_mistakes_MAD;
%         m_unlabeled_num_mistakes_CSSLMC;
        m_LP_result;
        m_MAD_result;
        m_CSSL_result
        m_CSSLMC_result;
        
%         m_unlabeled_LP_prediction;        
%         m_unlabeled_MAD_prediction;
%         m_unlabeled_CSSLMC_prediction;
    end
    
    methods (Access=public)
        function this = SingleRun() % Constructor
            this.m_labeled = [];
            this.m_unlabeled_final_mu = [];
            this.m_unlabeled_final_confidence = [];
            this.m_unlabeled_prediction = [];
            this.m_unlabeled_correct_labels = [];
            this.m_unlabeled_margin = [];
            this.m_unlabeled_is_correct = [];
            this.m_unlabeled_sorted.by_confidence = [];
            this.m_unlabeled_correct_label = [];
            this.m_unlabeled_num_mistakes = zeros( this.numAlgorithms(),1 );
            %this.m_unlabeled_LP_prediction = [];
            %this.m_unlabeled_MAD_prediction = [];
            %this.m_unlabeled_CSSLMC_prediction = [];
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
                
        function r = unlabeled_prediction(this, algorithmType)
            %if isempty( this.m_unlabeled_final_mu )
            algorithmResults = this.getAlgorithmResults( algorithmType );
            
            r = algorithmResults.binaryPrediction();
            r( this.labeled() ) = [];
            %end
            %r = this.m_unlabeled_final_mu;
        end
        
        %% Return final confidence for unlabeled vertices
        
        function r = unlabeled_final_confidence(this)
            if isempty( this.m_unlabeled_final_confidence )
                this.m_unlabeled_final_confidence = this.final_confidence();
                this.m_unlabeled_final_confidence( this.labeled() ) = [];
            end
            r = this.m_unlabeled_final_confidence;
        end
        
        %% calculate margin for unlabeled vertices
        
        function r = unlabeled_margin(this, algorithmType)
            %if isempty( this.m_unlabeled_margin )
            r = this.unlabeled_prediction(algorithmType) .* ...
                    this.unlabeled_correct_labels();
            %end
            %r = this.m_unlabeled_margin;
        end
        
        %% get number of unlabeled vertices
        
        function r = numUnlabeledVertices(this)
            numVertices = length(this.correctLabels);
            numLabeled = length(this.labeledPositive) + ...
                         length(this.labeledNegative) ;
            r = numVertices - numLabeled;
        end
        
        %% get result sorted by confidence
        
        function r = sorted_by_confidence( this )
            if isempty(this.m_unlabeled_sorted.by_confidence)
                this.calsSortedByConfidence();
            end
            r = this.m_unlabeled_sorted.by_confidence;
        end
        
%         function r = final_mu(this)
%             r = this.result.mu(:,end);
%         end
        
%         %% get correct label for unalbeled vertices
%         
%         function r = unlabeled_correct_label(this)
%             if isempty(this.m_unlabeled_correct_label)
%                 this.m_unlabeled_correct_label = this.correctLabels;
%                 this.m_unlabeled_correct_label( this.labeled() ) = [];
%             end
%             r = this.m_unlabeled_correct_label;
%         end
%         
%         %% get prediction for unalbeled vertices (LP algorithm)
%         
%         function r = unlabeled_LP_prediction(this)
%             if isempty(this.m_unlabeled_LP_prediction)
%                 this.m_unlabeled_LP_prediction = this.LP.Y;
%                 this.m_unlabeled_LP_prediction( this.labeled() ) = [];
%             end
%             r = this.m_unlabeled_LP_prediction;
%         end
%         
%         %% get prediction for unalbeled vertices (MAD algorithm)
%         
%         function r = unlabeled_MAD_prediction(this)
%             if isempty(this.m_unlabeled_MAD_prediction)
%                 this.m_unlabeled_MAD_prediction = ...
%                     this.m_MAD_result.binaryPrediction();
%                 this.m_unlabeled_MAD_prediction( this.labeled() ) = [];
%             end
%             r = this.m_unlabeled_MAD_prediction;
%         end
%         
%         %% get prediction for unalbeled vertices (CSSLMC algorithm)
%         
%         function r = unlabeled_CSSLMC_prediction(this)
%             if isempty(this.m_unlabeled_CSSLMC_prediction)
%                 this.m_unlabeled_CSSLMC_prediction = ...
%                     this.m_CSSLMC_result.binaryPrediction();
%                 this.m_unlabeled_CSSLMC_prediction( this.labeled() ) = [];
%             end
%             r = this.m_unlabeled_CSSLMC_prediction;
%         end
        
%         %% get number of mistakes (on unlabeled data) using LP algorithm
%         
%         function r = unlabeled_num_mistakes_LP(this)
%             if isempty(this.m_unlabeled_num_mistakes_LP)
%                 prediction = this.unlabeled_LP_prediction();
%                 this.m_unlabeled_num_mistakes_LP = ...
%                     this.unlabeled_num_mistakes_binary(prediction);
%             end
%             r = this.m_unlabeled_num_mistakes_LP ;
%         end
        
        %% get number of mistakes (on unlabeled data) for pecific algorithm
        
        function r = unlabeled_num_mistakes(this, algorithmType)
            if isempty(this.m_unlabeled_num_mistakes(algorithmType))
                algorithmResult = this.getAlgorithmResults( algorithmType );
                prediction = algorithmResult.binaryPrediction();
                this.m_unlabeled_num_mistakes(algorithmType) = ...
                    this.unlabeled_num_mistakes_binary(prediction);
            end
            r = this.m_unlabeled_num_mistakes(algorithmType) ;
        end
        
%         %% get number of mistakes (on unlabeled data) using MAD algorithm
%         
%         function r = unlabeled_num_mistakes_MAD(this)
%             if isempty(this.m_unlabeled_num_mistakes_MAD)
%                 prediction = this.unlabeled_MAD_prediction();
%                 this.m_unlabeled_num_mistakes_MAD = ...
%                     this.unlabeled_num_mistakes_binary(prediction);
%             end
%             r = this.m_unlabeled_num_mistakes_MAD ;
%         end
%         
%         %% get number of mistakes (on unlabeled data) using CSSLMC algorithm
%         
%         function r = unlabeled_num_mistakes_CSSLMC(this)
%             if isempty(this.m_unlabeled_num_mistakes_CSSLMC)
%                 prediction = this.unlabeled_CSSLMC_prediction();
%                 this.m_unlabeled_num_mistakes_CSSLMC = ...
%                     this.unlabeled_num_mistakes_binary(prediction);
%             end
%             r = this.m_unlabeled_num_mistakes_CSSLMC ;
%         end
        
    end % (Access=public)
    
    methods (Access = private)
        
        function r = final_confidence(this)
            r = this.result.v(:,end);
        end
        
        function r = unlabeled_num_mistakes_binary(this, binaryPrediction)
            correct    = this.unlabeled_correct_label();
            isCorrect = (sign(binaryPrediction) == correct);
            isWrong    = 1 - isCorrect;
            r = sum(isWrong);
        end
        
        %% Return indices for unlabeled vertices
        
        function r = labeled(this)
            if isempty( this.m_labeled )
                this.m_labeled  = ...
                    [this.labeledPositive;
                     this.labeledNegative];
            end
            r = this.m_labeled ;
        end
        
        %% Return unlabeled prediction
        
        function r = unlabeled_prediction(this)
            if isempty(this.m_unlabeled_prediction)
                calc_unlabeled_prediction(this);
            end
            r = this.m_unlabeled_prediction;
        end
        
        %% Calculate unlabeled prediction from unlabeled final mu
        
        function calc_unlabeled_prediction(this)
            numClasses = size( this.classToLabelMap, 1);
            range = linspace(this.negativeInitialValue, ...
                             this.positiveInitialValue, numClasses + 1);

            prediction = this.unlabeled_final_mu() ;
            classValueMap = [-1; +1];
            for range_i = 1:numClasses
                bottom = range(range_i);
                top = range(range_i + 1);
                prediction(bottom <= prediction & prediction < top) = ...
                    classValueMap(range_i);
            end
            this.m_unlabeled_prediction = prediction;
        end
        
        %% Calculate if prediction for unlabeled is correct
        
        function r = unlabeled_is_correct(this)
            if isempty( this.m_unlabeled_is_correct )
                this.m_unlabeled_is_correct = ...
                    (   this.unlabeled_prediction() == ...
                        this.unlabeled_correct_labels() );                
            end
            r = this.m_unlabeled_is_correct;
        end
        
        %% calculate correct vertices for unlabeled vertices
        
        function r = unlabeled_correct_labels(this)
            if isempty( this.m_unlabeled_correct_labels )
                this.m_unlabeled_correct_labels = this.correctLabels;
                this.m_unlabeled_correct_labels( this.labeled() ) = [];
            end
            r = this.m_unlabeled_correct_labels;
        end
        
        %%
        
        function calsSortedByConfidence(this)
            [values,indices] = sort( this.unlabeled_final_confidence() );

            isCorrect = this.unlabeled_is_correct();
            margin  = this.unlabeled_margin();
            
            sorted.by_confidence.confidence = values;
            sorted.by_confidence.correct = isCorrect(indices);
            sorted.by_confidence.wrong = ...
                1 - sorted.by_confidence.correct;
            sorted.by_confidence.margin = margin( indices );
            sorted.by_confidence.accumulative = ...
                cumsum(sorted.by_confidence.wrong);

            this.m_unlabeled_sorted.by_confidence = sorted.by_confidence;
        end
        
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