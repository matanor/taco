classdef Evaluation
    %EVALUATION Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Static)
        function [PRBEP precision recall] = calcPRBEP( Y_hat_l, Y_l )
        %%
        %   Y_hat_l - classifier scores for each example for class l.
        %   Y_l     - correct labeling of examples to class l (binary
        %   vector - a value of 1 indicates that the vertex belong to the
        %   label).
        
            thresholdRange = sort(Y_hat_l, 'descend').';
            minDifference  = Inf;
            
            i = 1;
            p_i = zeros( size(thresholdRange) );
            r_i = zeros( size(thresholdRange) );
            for threshold=thresholdRange
                precision   = Evaluation.calcPrecision ( Y_hat_l, Y_l, threshold );
                if (precision == 0)
                    continue; %ignore this case as a rule of thumb
                end
                recall      = Evaluation.calcRecall( Y_hat_l, Y_l, threshold );
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
        
        function r = calcPrecision( Y_hat_l, Y_l, threshold )
            belongToClass = (Y_hat_l >= threshold);
            r = sum(belongToClass .* Y_l) / sum(belongToClass);
        end
        
        function r = calcRecall( Y_hat_l, Y_l, threshold )
            belongToClass = (Y_hat_l >= threshold);
            r = sum(belongToClass .* Y_l) / sum(Y_l);
        end

    end
    
    methods
    end
    
end

