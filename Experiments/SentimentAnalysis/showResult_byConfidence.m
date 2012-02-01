function showResult_byConfidence...
    (   confidence, prediction, margin, ...
        isCorrect , classValue, labelValue )
%SHOWRESULT_BYCONFIDENCE Summary of this function goes here
%   Detailed explanation goes here

[sortedConfidence,confidenceSortIndex] = sort(confidence);
correctSortedAccordingToConfidence = ...
    isCorrect(confidenceSortIndex);
marginSortedAccordingToConfidence = ...
    margin(confidenceSortIndex);
predictionSortedAccordingToConfidence = ...
    prediction(confidenceSortIndex);
wrong = 1 - correctSortedAccordingToConfidence;
accumulativeLoss = cumsum(wrong);
%%

numRows = 4;
numCols = 1;

t = ['Results for class ' num2str(classValue) ... 
     ' (label value = ' num2str(labelValue) ')'];
figure('name', t);

subplot(numRows,numCols,1);
plot(accumulativeLoss);
title('accumulative loss sorted by confidence');

subplot(numRows,numCols,2);
plot(sortedConfidence);
title('sorted confidence');

subplot(numRows,numCols,3);
scatter(1:length(predictionSortedAccordingToConfidence),...
        predictionSortedAccordingToConfidence);
title('prediction sorted according to confidence');

subplot(numRows,numCols,4);
scatter(1:length(marginSortedAccordingToConfidence), ...
        marginSortedAccordingToConfidence );
title('margin sorted according to confidence ');

filename = ['resultsPerClass/class.' num2str(classValue) ... 
     '.value.' num2str(labelValue) '.fig'];
saveas(gcf,filename);

end

