function plotIndex = ...
        plotNumMistakes( numMistakes, param, ...
                          paramName, titleDetail, plotIndex )
%PLOTNUMMISTAKES Summary of this function goes here
%   Detailed explanation goes here

len = length(numMistakes);
t = [titleDetail ' Vs ' paramName];

subplot(plotIndex.rows, plotIndex.cols, plotIndex.current);
plotIndex.current = plotIndex.current + 1;
scatter(1:len, numMistakes) ;
title(t);
%legend('# mistakes');
xlabel('experiment ID');
ylabel('# mistakes');

subplot(plotIndex.rows, plotIndex.cols,plotIndex.current);
plotIndex.current = plotIndex.current + 1;
plot( param, 'r' );
title(t);
%legend(paramName);
xlabel('experiment ID');
ylabel(paramName);

end

