classdef SingleRun < handle
    %SINGLERUN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        correctLabels;
    end
   
    properties (Constant)
        LP = 1;
        CSSL = 2;
        CSSLMC = 3;
        MAD = 4;
        CSSLMCF = 5;
        AM = 6;
    end
    
    methods (Static)
        function r = numAvailableAlgorithms()
            r = 6;
        end
    end
    
    properties (Access=public)
        m_constructionParams;

        m_unlabeled_num_mistakes;
        
        m_LP_result;
        m_MAD_result;
        m_CSSL_result
        m_CSSLMC_result;
        m_CSSLMCF_result;
        m_AM_result;
        
        m_algorithmsCollection;
        m_trunsductionSet;
    end
    
    methods (Access=public)
        function this = SingleRun...
                (correctLabels, constructionParams, trunsductionSet) % Constructor
            this.correctLabels          = correctLabels;
            this.m_constructionParams   = constructionParams;
            this.m_trunsductionSet      = trunsductionSet;
            
            this.m_unlabeled_num_mistakes = zeros( SingleRun.numAvailableAlgorithms(),1 );
            this.m_algorithmsCollection = AlgorithmsCollection;
        end
        
        %% availableResultsAlgorithmRange
        
        function R = availableResultsAlgorithmRange(this)
            R = this.m_algorithmsCollection.algorithmsRange();
        end
        
        %% isResultsAvailable
        
        function r = isResultsAvailable( this, algorithmType )
            r = this.m_algorithmsCollection.shouldRun(algorithmType);
        end

        %% set_trunsductionSet
        
        function set_trunsductionSet(this, value)
            this.m_trunsductionSet = value;
        end
        
        %% constructionParams
        
        function R = constructionParams(this)
            R = this.m_constructionParams;
        end
        
        %% set_constructionParams
        
        function set_constructionParams(this, value)
            this.m_constructionParams = value;
        end
        
        %% getParams
        
        function R = getParams(this, algorithmType)
            algorithmResults = this.getAlgorithmResults( algorithmType );
            R = algorithmResults.getParams();
        end
        
        %% numIterations
        
        function R = numLabels(this)
            R = length(unique(this.correctLabels));
        end
        
        %% testSetSize
        
        function R = testSetSize(this)
            R = length(this.testSet());
        end
        
        %% numIterations
        
        function R = numIterations(this, algorithmType)
            R = this.getParams(algorithmType);
            R = R.maxIterations;
        end
        
        %% set_results
        
        function set_results( this, R, algorithmType )
            if (algorithmType == this.LP)
                this.m_LP_result = R;
            elseif (algorithmType == this.MAD)
                this.m_MAD_result = R;
            elseif (algorithmType == this.CSSL)
                this.m_CSSL_result = R;
            elseif (algorithmType == this.CSSLMC)
                this.m_CSSLMC_result = R;
            elseif (algorithmType == this.CSSLMCF)
                this.m_CSSLMCF_result = R;
            elseif (algorithmType == this.AM)
                this.m_AM_result = R;
            end
            this.m_algorithmsCollection.setRun( algorithmType );
        end
        
        %% Return prediction (multi-class) for unlabeled vertices
        
        function r = unlabeled_prediction(this, algorithmType)
            algorithmResults = this.getAlgorithmResults( algorithmType );

            r = algorithmResults.prediction();
            r( this.labeled() ) = [];
        end
        
        %% Return prediction (multi-class) for test set
        
        function r = testSet_prediciton(this, algorithmType)
            algorithmResults = this.getAlgorithmResults( algorithmType );

            r = algorithmResults.prediction();
            r( this.trainSet() ) = [];            
        end
        
        %% Return score matrix (multi-class) for unlabeled vertices
        
        function r = unlabeled_scoreMatrix(this, algorithmType)
            algorithmResults = this.getAlgorithmResults( algorithmType );

            r = algorithmResults.getFinalScoreMatrix();
            r( this.labeled(), : ) = [];
        end
        
        %% Return score matrix (multi-class) for unlabeled vertices
        %  in test set
        
        function r = unlabeled_scoreMatrix_testSet(this, algorithmType)
            algorithmResults = this.getAlgorithmResults( algorithmType );

            r = algorithmResults.getFinalScoreMatrix();
            r( this.trainSet(), : ) = [];
        end
        
        %% testSetCorrectLabels
        
        function r = testSetCorrectLabels(this)
            r = this.correctLabels;
            r( this.trainSet(), : ) = [];
        end
        
        %% calcPRBEP_testSet
        
        function [prbep precision recall] = calcPRBEP_testSet...
                (this, algorithmType, labelIndex)
            scoreMatrix = this.unlabeled_scoreMatrix_testSet(algorithmType);
            correctLabels_testSet = this.testSetCorrectLabels();
            scoreForLabel   = scoreMatrix(:,labelIndex);
            isCurrentLabel = (correctLabels_testSet == labelIndex);
            [prbep precision recall] = EvaluationUtilities.calcPRBEP...
                (scoreForLabel, isCurrentLabel );
        end
        
        %% calcMRR_testSet
        
        function MRR = calcMRR_testSet(this, algorithmType)
            scoreMatrix = this.unlabeled_scoreMatrix_testSet(algorithmType);
            correctLabels_testSet = this.testSetCorrectLabels();            
            MRR = EvaluationUtilities.calcMRR( scoreMatrix, correctLabels_testSet);
        end
        
        %% calcAveragePRBEP_testSet
        
        function R = calcAveragePRBEP_testSet(this, algorithmType)
            numLabels = this.numLabels();
            labelsPRBEP = zeros(numLabels,1);
            for label_i=1:numLabels
                [prbep,~,~] = this.calcPRBEP_testSet(algorithmType, label_i);
                labelsPRBEP(label_i) = prbep;
            end
            R = mean(prbep);
            Logger.log(['calcAveragePRBEP_testSet: ' num2str(R)]);
        end
        
        %% estimatePRBEP_testSet
        
        function [prbep] = estimatePRBEP_testSet...
                (this, algorithmType, labelIndex)
            testSet_prediction      = this.testSet_prediciton(algorithmType);
            correctLabels_testSet   = this.testSetCorrectLabels();
            
            isPredictedLabel = (testSet_prediction    == labelIndex);
            isCurrentLabel   = (correctLabels_testSet == labelIndex);
            p = EvaluationUtilities.calcPrecision(isPredictedLabel, isCurrentLabel );
            r = EvaluationUtilities.calcRecall   (isPredictedLabel, isCurrentLabel );
            prbep = (p + r)/2;
        end
        
        %% num_mistakes_testSet
        
        function r = num_mistakes_testSet(this, algorithmType)
            testSet_prediction      = this.testSet_prediciton(algorithmType);
            correctLabels_testSet   = this.testSetCorrectLabels();
            r = this.calcNumMistakes(testSet_prediction, correctLabels_testSet);
        end
        
        %% accuracy_testSet
        
        function r = accuracy_testSet(this, algorithmType)
            numMistakes = this.num_mistakes_testSet(algorithmType);
            testSetSize = this.testSetSize();
            numCorrect = testSetSize - numMistakes;
            r = numCorrect / testSetSize;
        end
       
        %% Return binary prediction for unlabeled vertices
                
        function r = unlabeled_binary_prediction(this, algorithmType)
            algorithmResults = this.getAlgorithmResults( algorithmType );
            
            r = algorithmResults.binaryPrediction();
            r( this.labeled() ) = [];
        end
        
        %% Return final confidence for unlabeled vertices
        
        function r = unlabeled_confidence(this, algorithmType)
            algorithmResults = this.getAlgorithmResults( algorithmType );
            
            r = algorithmResults.predictionConfidence();
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
                prediction = this.unlabeled_prediction( algorithmType );
                this.m_unlabeled_num_mistakes(algorithmType) = ...
                    this.calcNumMistakes(prediction, this.unlabeled_correct_labels());
            end
            r = this.m_unlabeled_num_mistakes(algorithmType) ;
        end
        
        %% calculate correct vertices for unlabeled vertices
        %  (for all algorithms this is the same)
        
        function r = unlabeled_correct_labels(this)
            %if isempty( this.m_unlabeled_correct_labels )
            %    this.m_unlabeled_correct_labels = this.correctLabels;
            %    this.m_unlabeled_correct_labels( this.labeled() ) = [];
            %end
            r = this.correctLabels;
            r( this.labeled() ) = [];
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
            elseif (algorithmType == this.CSSLMCF)
                r = this.m_CSSLMCF_result;
            elseif (algorithmType == this.AM)
                r = this.m_AM_result;
            end
        end
        
    end % (Access=public)
    
    methods (Access = private)
        
        %% Return indices for labeled vertices
        
        function r = labeled(this)
            r = this.m_trunsductionSet.labeled();
        end
        
        %% trainSet
        
        function R = trainSet(this)
            R = this.m_trunsductionSet.trainingSet();
        end
        
        %% testSet
        
        function R = testSet(this)
            R = this.m_trunsductionSet.testSet();
        end
        
        %% calcNumMistakes
        
        function r = calcNumMistakes(~, prediction, correct)
            isCorrect = (correct == prediction);
            isWrong    = 1 - isCorrect;
            r = sum(isWrong);            
        end
        
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

    end % (Access = private)
    
end