classdef Evaluation
    %EVALUATION Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Static)
        function [PRBEP precision recall] = calcPRBEP( Y_scores_l, Y_l )
        %%
        %   Y_scores_l  - classifier scores for each example for class l.
        %   Y_l         - correct labeling of examples to class l (binary)
        %   vector      - a value of 1 indicates that the vertex belong to the
        %   label).
        
            thresholdRange = sort(Y_scores_l, 'descend').';
            minDifference  = Inf;
            
            i = 1;
            p_i = zeros( size(thresholdRange) );
            r_i = zeros( size(thresholdRange) );
            for threshold=thresholdRange
                precision = Evaluation.calcPrecision_byThreshold ( Y_scores_l, Y_l, threshold );
                if (precision == 0)
                    continue; %ignore this case as a rule of thumb
                end
                recall = Evaluation.calcRecall_byThreshold( Y_scores_l, Y_l, threshold );
                p_i(i) = precision;
                r_i(i) = recall;
                i = i + 1;
                difference = abs(precision - recall);
                if difference < minDifference
                    PRBEP = precision;  % found a better point where the recall 
                                    % and precision are close.
                    minDifference = difference;
                end
            end
            if (minDifference ~= 0)
                disp(['Precision recall difference = ' num2str(minDifference)]);
            end
            precision = p_i;
            recall = r_i;
        end
        
        %% calcPrecision_byThreshold
        
        function r = calcPrecision_byThreshold( Y_scores_l, Y_l, threshold )
            belongToClass = (Y_scores_l >= threshold);
            r = Evaluation.calcPrecision(belongToClass, Y_l);
        end
        
        %% calcRecall_byThreshold
        
        function r = calcRecall_byThreshold( Y_scores_l, Y_l, threshold )
            belongToClass = (Y_scores_l >= threshold);
            r = Evaluation.calcRecall(belongToClass, Y_l);
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
        
        function test()
            scores = rand(10,1);
            threshold = median(a);
            correct = (scores > threshold);
            [prbep, precision,recall] = Evaluation.calcPRBEP(scores, correct);
            showSingleRunResults.plotPrecisionAndRecall(precision, recall, 'test');
            disp(['prbep = ' num2str(prbep)]);
        end

    end
    
    methods
    end
    
end

