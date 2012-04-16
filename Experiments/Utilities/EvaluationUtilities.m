classdef EvaluationUtilities
    %EVALUATION Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Static)
        function [PRBEP precision recall minDifference] = ...
                calcPRBEP( Y_scores_l, Y_l )
        %%
        %   Y_scores_l  - classifier scores for each example for class l.
        %   Y_l         - correct labeling of examples to class l (binary)
        
            thresholdRange = sort(Y_scores_l, 'descend').';
            minDifference  = Inf;
            
            i = 1;
            p_i = zeros( size(thresholdRange) );
            r_i = zeros( size(thresholdRange) );
            for threshold=thresholdRange
                precision = EvaluationUtilities.calcPrecision_byThreshold ( Y_scores_l, Y_l, threshold );
                if (precision == 0)
                    continue; %ignore this case as a rule of thumb
                end
                recall = EvaluationUtilities.calcRecall_byThreshold( Y_scores_l, Y_l, threshold );
                p_i(i) = precision;
                r_i(i) = recall;
                i = i + 1;
                difference = abs(precision - recall);
                if difference < minDifference
                    PRBEP_precision = precision;
                    PRBEP_recall = recall;
                    %PRBEP = precision;  % found a better point where the recall 
                                    % and precision are close.
                    minDifference = difference;
                end
            end
            if (minDifference ~= 0)
                Logger.log(['EvaluationUtilities::calcPRBEP. ' ...
                            'Precision recall difference = ' num2str(minDifference)]);
                PRBEP = (PRBEP_precision + PRBEP_recall) / 2;
            else
                PRBEP = PRBEP_precision;
            end
            precision = p_i;
            recall = r_i;
        end
        
        %% calcPrecision_byThreshold
        
        function r = calcPrecision_byThreshold( Y_scores_l, Y_l, threshold )
            belongToClass = (Y_scores_l >= threshold);
            r = EvaluationUtilities.calcPrecision(belongToClass, Y_l);
        end
        
        %% calcRecall_byThreshold
        
        function r = calcRecall_byThreshold( Y_scores_l, Y_l, threshold )
            belongToClass = (Y_scores_l >= threshold);
            r = EvaluationUtilities.calcRecall(belongToClass, Y_l);
        end

        %% calcPrecision
        %   Y_hat_l     - predicted labeling of examples to class L (binary)
        %   Y_l         - correct labeling of examples to class L (binary)
        
        function r = calcPrecision( Y_hat_l, Y_l )
            r = sum(Y_hat_l .* Y_l) / sum(Y_hat_l);
        end
        
        %% calcRecall
        %   Y_hat_l     - predicted labeling of examples to class L (binary)
        %   Y_l         - correct labeling of examples to class L (binary)
        
        function r = calcRecall( Y_hat_l, Y_l )
            r = sum(Y_hat_l .* Y_l) / sum(Y_l);
        end

        %% calcMRR 
        % scores - an array of (num_examples X numLabels) with label
        % scores.
        % correctLabel - a vector containing the corect label index for
        % every example
        
        function r = calcMRR( scores, correctLabel )
            numInstances = size(scores,1);
            MRR = 0;
            for instance_i=1:numInstances
                instanceScores = scores(instance_i,:).';
                [~, sortedLabels] = sort(instanceScores, 'descend');
                instanceCorrectLabel = correctLabel(instance_i);
                correctLabelRank = find(sortedLabels == instanceCorrectLabel);
                MRR = MRR + 1/correctLabelRank;
            end
            MRR = MRR / numInstances;
            r = MRR;
        end
        
        %% calc_macroMRR 
        % scores - an array of (num_examples X numLabels) with label
        % scores.
        % correctLabel - a vector containing the corect label index for
        % every example
        % This function first calculates an MRR per class L by looking
        % only at instances with the true label L. Then,
        % the macro MRR is the sum of MRR per each class,
        % divided by the number of classes K.
        
        function r = calc_macroMRR( scores, correctLabel )
            numInstances = size(scores,1);
            numLabels    = size(scores, 2);
            MRR = zeros(numLabels,1);
            numInstancesPerClass = zeros(numLabels,1);
            for instance_i=1:numInstances
                instanceScores = scores(instance_i,:).';
                [~, sortedLabels] = sort(instanceScores, 'descend');
                instanceCorrectLabel = correctLabel(instance_i);
                correctLabelRank = find(sortedLabels == instanceCorrectLabel);
                MRR(instanceCorrectLabel) = ...
                    MRR(instanceCorrectLabel) + 1/correctLabelRank;
                numInstancesPerClass(instanceCorrectLabel) = ...
                    numInstancesPerClass(instanceCorrectLabel) + 1;
            end
            MRR = MRR ./ numInstancesPerClass;
            r = mean(MRR);
        end
        
        %% testPRBEP
        
        function testPRBEP()
            scores = rand(10,1);
            threshold = median(scores);
            correct = (scores > threshold);
            [prbep, precision,recall] = EvaluationUtilities.calcPRBEP(scores, correct);
            showSingleRunResults.plotPrecisionAndRecall(precision, recall, 'test');
            Logger.log(['prbep = ' num2str(prbep)]);
        end
        
        %% testMRR
        
        function testMRR()
            rand('twister',sum(100*clock)); %#ok<RAND>
            numInstances = 10;
            numLabels = 4;
            scores = rand(numInstances,numLabels);
            correctLabel = randi(numLabels,numInstances,1);
            MRR         = EvaluationUtilities.calcMRR(scores, correctLabel);
            macro_MRR   = EvaluationUtilities.calc_macroMRR(scores, correctLabel);
            Logger.log(['MRR = ' num2str(MRR)]);
            Logger.log(['macro MRR = ' num2str(macro_MRR)]);
        end

    end
    
    methods
    end
    
end

