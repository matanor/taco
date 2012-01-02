function plotPrecentageDiff( numMistakes_1, numMistakes_2,...
                             numMistakes_final,...
                             paramsOrder, figurePath)
%PLOTPRECENTAGEDIFF Summary of this function goes here
%   Detailed explanation goes here


precentMistakes.first = numMistakes_1;
precentMistakes.second = numMistakes_2;

diff = precentMistakes.second - precentMistakes.first;

[sorted,experiment_id_sorted_by_diff] = sort(diff);

%%

figure('name',figurePath);
len = length(sorted);

plotIndex.rows = 4;
plotIndex.cols = 2;
plotIndex.current = 1;

subplot(plotIndex.rows, plotIndex.cols, plotIndex.current);
plotIndex.current = plotIndex.current + 1;

t = 'Precentage difference';
scatter(1:len, sorted) ;
title(t);
ylabel('# mistakes');

subplot(plotIndex.rows, plotIndex.cols, plotIndex.current);
plotIndex.current = plotIndex.current + 1;
t = 'Total mistakes';
scatter(1:len, numMistakes_final(experiment_id_sorted_by_diff)) ;
title(t);
ylabel('# mistakes');

subplot(plotIndex.rows, plotIndex.cols,plotIndex.current);
plotIndex.current = plotIndex.current + 1;

scatter( 1:len, experiment_id_sorted_by_diff, 'r' );
title('experiment ID by sorted precentage difference');
ylabel('experiment ID');

subplot(plotIndex.rows, plotIndex.cols, plotIndex.current);
plotIndex.current = plotIndex.current + 1;

scatter( 1:len, ...
    paramsOrder.K(experiment_id_sorted_by_diff), 'r' );
title('K sorted precentage difference');
ylabel('K');

subplot(plotIndex.rows, plotIndex.cols, plotIndex.current);
plotIndex.current = plotIndex.current + 1;

scatter( 1:len, ...
    paramsOrder.alpha(experiment_id_sorted_by_diff), 'r' );
title('alpha sorted precentage difference');
ylabel('alpha');

subplot(plotIndex.rows, plotIndex.cols, plotIndex.current);
plotIndex.current = plotIndex.current + 1;

scatter( 1:len, ...
    paramsOrder.beta(experiment_id_sorted_by_diff), 'r' );
title('beta sorted precentage difference');
ylabel('beta');

subplot(plotIndex.rows, plotIndex.cols, plotIndex.current);
plotIndex.current = plotIndex.current + 1;

scatter( 1:len, ...
    paramsOrder.labeledConfidence(experiment_id_sorted_by_diff), 'r' );
title('gamma sorted precentage difference');
ylabel('gamma');

saveas(gcf, figurePath);
close(gcf);


end

