classdef Evaluation
    %EVALUATION Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Static)
        function r = calcPRBEP( Y_hat_l, Y_l, outputProperties )
        %%
        %   Y_hat_l - classifier scores for each example for class l.
        %   Y_l     - correct labeling of examples to class l.
        
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
                    r = precision;  % found a better point where the recall 
                                    % and precision are close.
                    minDifference = difference;
                end
            end
            %disp(['Precision recall difference = ' num2str(minDifference)]);
            Evaluation.plotPrecisionAndRecall(p_i, r_i, outputProperties);
        end
        
        function plotPrecisionAndRecall( precision, recall, outputProperties )
            %%
            outputDirectory = outputProperties.resultDir;
            folderName      = outputProperties.folderName;
            experimentID    = outputProperties.experimentID;
            run_i           = outputProperties.run_i;
            class_i         = outputProperties.class_i;

            t = ['precision and recall ' ...
                 'experimentID = ' num2str(experimentID) ...
                 ' run index =' num2str(run_i) ...
                 ' class index  =' num2str(class_i)];
            h = figure('name',t);
            hold on;
            plot(precision, 'r');
            plot(recall,    'g');
            hold off;
            title(t);
            legend('precision','recall');
            xlabel('threshold #i');
            ylabel('precision/recall');
            
            filename = [ outputDirectory folderName '\SingleResults.' ...
                         num2str(experimentID) '.' num2str(run_i) '.' ...
                         num2str(class_i) '.PrecisionRecall.fig'];
            saveas(h, filename); close(h);

%             h = figure;
% %             [sortedPrecision,indices] = sort(precision);
% %             sortedRecallByPrecision = recall(indices);
% %             scatter(sortedPrecision,sortedRecallByPrecision);
%             scatter(recall, precision);
%             xlabel('recall');
%             ylabel('precision');
%             saveas(h, filename); close(h);
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

