classdef SingleRun < handle
    %SINGLERUN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=public)
        labeledPositive;
        labeledNegative;
        correctLabels;
        positiveInitialValue;
        negativeInitialValue;
        classToLabelMap;
        result;
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
        end
       
        %% Return final mu for unlabeled vertices
                
        function r = unlabeled_final_mu(this)
            if isempty( this.m_unlabeled_final_mu )
                this.m_unlabeled_final_mu = ...
                    this.final_mu();
                this.m_unlabeled_final_mu( this.labeled() ) ...
                    = [];
            end
            r = this.m_unlabeled_final_mu;
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
        
        function r = unlabeled_margin(this)
            if isempty( this.m_unlabeled_margin )
                this.m_unlabeled_margin = ...
                    this.unlabeled_final_mu() .* ...
                    this.unlabeled_correct_labels();
            end
            r = this.m_unlabeled_margin;
        end
        
        %% get number of unlabeled vertices
        
        function r = num_unlabeled(this)
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
        
    end % (Access=public)
    
    methods (Access = private)

        function r = final_mu(this)
            r = this.result.mu(:,end);
        end
        
        function r = final_confidence(this)
            r = this.result.v(:,end);
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

    end % (Access = private)
end