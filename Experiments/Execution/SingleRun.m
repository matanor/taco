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
        QC = 7;
    end
    
    methods (Static)
        function r = numAvailableAlgorithms()
            r = 7;
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
        m_QC_result;
        
        m_algorithmsCollection;
        m_trunsductionSet;
        m_cachedResults;
        
        m_isCalcPRBEP;
        
        m_structuredSegments; % a <numSegments X 2> array, 
                              % with <segment start> <segment end> values
                              % per row. e.g. in speech each segment is a
                              % sentence.
        m_fileFullPath;       % path to file location where this single run
                              % result will be saved.
                              % temporary files paths are based on this
                              % parameter. (e.g. for levenshtein distance,
                              % the reference file path will be 
                              % <m_fileFullPath>.ref)
    end
    
    methods (Access=public)
        
        %% Constructor
        
        function this = SingleRun...
                (correctLabels, constructionParams, trunsductionSet) % Constructor
            this.correctLabels          = correctLabels;
            this.m_constructionParams   = constructionParams;
            this.m_trunsductionSet      = trunsductionSet;
            
            this.m_unlabeled_num_mistakes = zeros( SingleRun.numAvailableAlgorithms(),1 );
            this.m_algorithmsCollection = AlgorithmsCollection;
            this.m_cachedResults = [];
            if isfield(this.m_constructionParams.fileProperties, 'isCalcPRBEP')
                this.m_isCalcPRBEP = this.m_constructionParams.fileProperties.isCalcPRBEP;
            else
                this.m_isCalcPRBEP = 0;
            end
            Logger.log(['SingleRun::contructor(). m_isCalcPRBEP = ' ...
                         num2str(this.m_isCalcPRBEP)]);
        end
        
        %% set_fileFullPath
        
        function set_fileFullPath(this, value)
            this.m_fileFullPath = value;
        end
        
        %% set_structuredSegments
        
        function set_structuredSegments(this, value)
            this.m_structuredSegments = value;
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
        
        %% numLabels
        
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
        
        %% clearAlgorithmOutput
    
        function clearAlgorithmOutput(this)
            Logger.log('clearAlgorithmOutput');
            algorithmRange = this.availableResultsAlgorithmRange();
            for algorithm_i=algorithmRange
                algorithmResults = this.getAlgorithmResults(algorithm_i);
                algorithmResults.clearOutput();
            end
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
            elseif (algorithmType == this.QC)
                this.m_QC_result = R;                
            end
            this.m_algorithmsCollection.setRun( algorithmType );
        end
        
        %% unlabeled_prediction
        
        function r = unlabeled_prediction(this, algorithmType)
            algorithmResults = this.getAlgorithmResults( algorithmType );

            r = algorithmResults.prediction();
            r( this.labeled() ) = [];
        end
        
        %% testSet_prediciton
        
        function r = testSet_prediciton(this, algorithmType)
            algorithmResults = this.getAlgorithmResults( algorithmType );

            r = algorithmResults.prediction();
            r( this.trainSet() ) = [];            
        end
        
        %% unlabeled_scoreMatrix
        
        function r = unlabeled_scoreMatrix(this, algorithmType)
            algorithmResults = this.getAlgorithmResults( algorithmType );

            r = algorithmResults.getFinalScoreMatrix();
            r( this.labeled(), : ) = [];
        end
        
        %% unlabeled_scoreMatrix_testSet
        
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
        
        %% createCachedResults
        
        function createCachedResults(this)
            Logger.log('singleRun::createCachedResults');
            numLabels = this.numLabels();
            algorithmRange = this.availableResultsAlgorithmRange();
            for algorithm_i=algorithmRange
                prbepPerLabel = zeros(numLabels,1);
                for label_i=1:numLabels
                    [prbep precision recall] = ...
                        this.calcPRBEP_testSet(algorithm_i,label_i);
                    testSetResults{algorithm_i}.prbep{label_i}.value     = prbep; %#ok<AGROW>
                    testSetResults{algorithm_i}.prbep{label_i}.precision = precision; %#ok<AGROW>
                    testSetResults{algorithm_i}.prbep{label_i}.recall    = recall; %#ok<AGROW>
                    testSetResults{algorithm_i}.prbep{label_i}.estimated = ...
                        this.estimatePRBEP_testSet(algorithm_i,label_i); %#ok<AGROW>
                    prbepPerLabel(label_i) = prbep;
                end
                testSetResults{algorithm_i}.avgPRBEP      = mean(prbepPerLabel); %#ok<AGROW>
                testSetResults{algorithm_i}.MRR           = this.calcMRR_testSet(algorithm_i); %#ok<AGROW>
                testSetResults{algorithm_i}.macroMRR      = this.calc_macroMRR_testSet(algorithm_i); %#ok<AGROW>
                testSetResults{algorithm_i}.accuracy      = this.accuracy_testSet(algorithm_i); %#ok<AGROW>
                testSetResults{algorithm_i}.macroAccuracy = this.macroAccuracy_testSet(algorithm_i); %#ok<AGROW>
                testSetResults{algorithm_i}.levenshteinDistance = this.levenshteinDistance_testSet(algorithm_i);     %#ok<AGROW>
            end
            this.m_cachedResults = testSetResults;
        end

        %% hasCachedResults
        
        function R = hasCachedResults(this)
            R = (0 == isempty(this.m_cachedResults));
        end
        
        %% calcPRBEP_testSet
        
        function [prbep precision recall] = calcPRBEP_testSet...
                (this, algorithmType, labelIndex)
            if 0 == this.m_isCalcPRBEP
                prbep = 0;
                precision = 0;
                recall = 0;
                return; 
            end
            if this.hasCachedResults()
                prbep       = this.m_cachedResults{algorithmType}.prbep{labelIndex}.value;
                precision   = this.m_cachedResults{algorithmType}.prbep{labelIndex}.precision;
                recall      = this.m_cachedResults{algorithmType}.prbep{labelIndex}.recall;
                return;
            end
            scoreMatrix = this.unlabeled_scoreMatrix_testSet(algorithmType);
            correctLabels_testSet = this.testSetCorrectLabels();
            scoreForLabel   = scoreMatrix(:,labelIndex);
            isCurrentLabel = (correctLabels_testSet == labelIndex);
            [prbep precision recall difference] = EvaluationUtilities.calcPRBEP...
                (scoreForLabel, isCurrentLabel );
            if (difference ~=0 )
                Logger.log(['SingleRun::calcPRBEP_testSet. ' ...
                            'algorithm = ' AlgorithmTypeToStringConverter.convert(algorithmType) ...
                            ' label index = ' num2str(labelIndex)]);
            end
        end
        
        %% calcMRR_testSet
        
        function MRR = calcMRR_testSet(this, algorithmType)
            if this.hasCachedResults()
                MRR = this.m_cachedResults{algorithmType}.MRR;
            else
                scoreMatrix = this.unlabeled_scoreMatrix_testSet(algorithmType);
                correctLabels_testSet = this.testSetCorrectLabels();            
                MRR = EvaluationUtilities.calcMRR( scoreMatrix, correctLabels_testSet);
            end
        end
        
        %% calc_macroMRR_testSet
        
        function macroMRR = calc_macroMRR_testSet(this, algorithmType)
            if this.hasCachedResults()
                macroMRR = this.m_cachedResults{algorithmType}.macroMRR;
            else
                scoreMatrix = this.unlabeled_scoreMatrix_testSet(algorithmType);
                correctLabels_testSet = this.testSetCorrectLabels();            
                macroMRR = EvaluationUtilities.calc_macroMRR( scoreMatrix, correctLabels_testSet);
            end;
        end
        
        %% calcAveragePRBEP_testSet
        
        function R = calcAveragePRBEP_testSet(this, algorithmType)
            if 0 == this.m_isCalcPRBEP
                R = 0; 
                return;
            end
            if this.hasCachedResults()
                R = this.m_cachedResults{algorithmType}.avgPRBEP;
            else
                numLabels = this.numLabels();
                labelsPRBEP = zeros(numLabels,1);
                for label_i=1:numLabels
                    [prbep,~,~] = this.calcPRBEP_testSet(algorithmType, label_i);
                    labelsPRBEP(label_i) = prbep;
                    clear prbep;
                end
                R = mean(labelsPRBEP);
            end
            Logger.log(['calcAveragePRBEP_testSet: ' num2str(R)]);
        end
        
        %% estimatePRBEP_testSet
        
        function [prbep] = estimatePRBEP_testSet...
                (this, algorithmType, labelIndex)
            if 0 == this.m_isCalcPRBEP
                prbep = 0; 
                return;
            end
            if this.hasCachedResults()
                prbep = this.m_cachedResults{algorithmType}.prbep{labelIndex}.estimated;
            else
                testSet_prediction      = this.testSet_prediciton(algorithmType);
                correctLabels_testSet   = this.testSetCorrectLabels();
            
                isPredictedLabel = (testSet_prediction    == labelIndex);
                isCurrentLabel   = (correctLabels_testSet == labelIndex);
                p = EvaluationUtilities.calcPrecision(isPredictedLabel, isCurrentLabel );
                r = EvaluationUtilities.calcRecall   (isPredictedLabel, isCurrentLabel );
                prbep = (p + r)/2;
            end
        end
        
        %% num_mistakes_testSet
        
        function r = num_mistakes_testSet(this, algorithmType)
            testSet_prediction      = this.testSet_prediciton(algorithmType);
            correctLabels_testSet   = this.testSetCorrectLabels();
            r = this.calcNumMistakes(testSet_prediction, correctLabels_testSet);
        end
        
        %% accuracy_testSet
        
        function r = accuracy_testSet(this, algorithmType)
            if this.hasCachedResults()
                r = this.m_cachedResults{algorithmType}.accuracy;
            else
                numMistakes = this.num_mistakes_testSet(algorithmType);
                testSetSize = this.testSetSize();
                numCorrect = testSetSize - numMistakes;
                r = numCorrect / testSetSize;
            end
        end
        
        %% macroAccuracy_testSet
        
        function R = macroAccuracy_testSet(this, algorithmType)
            if this.hasCachedResults()
                R = this.m_cachedResults{algorithmType}.macroAccuracy;
            else
                testSet_prediction      = this.testSet_prediciton(algorithmType);
                correctLabels_testSet   = this.testSetCorrectLabels();
                numLabels = this.numLabels();
                accuracyPerLabel = zeros(numLabels,1);
                for label_i=1:numLabels
                    predictionPerLabel = testSet_prediction( correctLabels_testSet == label_i );
                    numCorrect = sum( predictionPerLabel == label_i );
                    numInstancesPerClass = sum( correctLabels_testSet == label_i );
                    accuracyPerLabel(label_i) = numCorrect / numInstancesPerClass;
                end
                R = mean(accuracyPerLabel);
            end
        end
        
        %% hasStructuredSegments
        
        function R = hasStructuredSegments(this)
            R = ~isempty(this.m_structuredSegments);
        end
        
        %% levenshteinDistance_testSet
        %  calculate the levenshtein distance, on the test set.
        %  This applies to structured prediction.
        
        function R = levenshteinDistance_testSet(this, algorithmType)
            if ~this.hasStructuredSegments()
                Logger.log('singleRun::levenshteinDistance_testSet. No structured segmments, skipping...')
                R = 0;
                return;
            end
            if this.hasCachedResults()
                R = this.m_cachedResults{algorithmType}.levenshteinDistance;
            else
                testSet_prediction      = this.testSet_prediciton(algorithmType);
                testSet_correctLabels   = this.testSetCorrectLabels();
                [path,fileName,~] = fileparts(this.m_fileFullPath);
                outputPrefix = [path '/' fileName];
                testSet_segments        = this.testSet_segments();
                levenshteinDistance = LevenshteinDistance;
                R = levenshteinDistance.calculate...
                        (testSet_prediction, testSet_correctLabels, ...
                         testSet_segments,   outputPrefix);
            end
        end
        
        %% testSet_segments
        
        function R = testSet_segments(this)
            numSegments = size(this.m_structuredSegments,1);
            Logger.log(['SingleRun::testSet_segments. total number of segments = ' num2str(numSegments)]);
            segments = this.m_structuredSegments;
            SEGMENT_START_POSITION = 1;
            SEGMENT_END_POSITION   = 2;
            testSet = this.testSet();
            testSegments = [];
            for segment_i=1:numSegments
                segmentStart = segments(segment_i, SEGMENT_START_POSITION);
                segmentEnd   = segments(segment_i, SEGMENT_END_POSITION);
                if ismember(segmentStart,testSet)
                    assert( ismember( segmentEnd, testSet ) );
                    testSegments = [testSegments; segmentStart segmentEnd]; %#ok<AGROW>
                end
            end
            numTestSegments = size(testSegments, 1);
            Logger.log(['SingleRun::testSet_segments. Number of test segments = ' num2str(numTestSegments)]);
            
            testSetStartOffset = testSet(1);
            testSegments = testSegments - testSetStartOffset + 1;
            Logger.log(['SingleRun::testSet_segments. First test segment starts at = ' num2str(testSegments(1,1))]);
            Logger.log(['SingleRun::testSet_segments. Last test segment ends at = ' num2str(testSegments(end,end))]);
            
            R = testSegments;
        end
       
        %% unlabeled_binary_prediction
                
        function r = unlabeled_binary_prediction(this, algorithmType)
            algorithmResults = this.getAlgorithmResults( algorithmType );
            
            r = algorithmResults.binaryPrediction();
            r( this.labeled() ) = [];
        end
        
        %% unlabeled_confidence
        
        function r = unlabeled_confidence(this, algorithmType)
            algorithmResults = this.getAlgorithmResults( algorithmType );
            
            r = algorithmResults.predictionConfidence();
            r( this.labeled() ) = [];
        end
        
        %% unlabeled_margin
        
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
            elseif (algorithmType == this.QC)
                r = this.m_QC_result;
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