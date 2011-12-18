%%

numExperiments = 1;
numLabeled = 50;
numInstancesPerClass = 500;
numIterations = 50;
k10  = avg_experiment(numExperiments,   10, numLabeled, numInstancesPerClass, numIterations);
k20  = avg_experiment(numExperiments,   20, numLabeled, numInstancesPerClass, numIterations);
k100 = avg_experiment(numExperiments,  100, numLabeled, numInstancesPerClass, numIterations);

%% Compare K
numRows = 2;
numCols = 1;
t = ['effect of K-nn graph.'...
     ' numExperiments = ' num2str(numExperiments)...
     ', numLabeled = ' num2str(numLabeled)];
figure('name', t);
subplot(numRows,numCols,1);
hold on;
plot(k10.accumulativeLoss,  'r');
plot(k20.accumulativeLoss,  'g');
plot(k100.accumulativeLoss,  'b');
title('accumulative loss sorted by confidence');
legend('k=10','k=20','k=100');
subplot(numRows,numCols,2);
hold on;
plot(k10.sortedConfidence,  'r');
plot(k20.sortedConfidence,  'g');
plot(k100.sortedConfidence,  'b');
title('sorted confidence');
legend('k=10','k=20','k=100');

%%

numRows = 3;
numCols = 1;
t = ['margin sorted by confidence.'...
     ' numExperiments = ' num2str(numExperiments)...
     ', numLabeled = ' num2str(numLabeled)];
figure('name',t);
len = length(k10.sortedMargin);

subplot(numRows,numCols,1);
scatter(1:len, k10.sortedMargin,  'r');
title('sorted margin k = 10');

subplot(numRows,numCols,2);
scatter(1:len, k20.sortedMargin,  'g');
title('sorted margin k = 20');

subplot(numRows,numCols,3);
scatter(1:len, k100.sortedMargin,  'b');
title('sorted margin k = 100');

filename = 'results weighted (and 2)/effect of K.sorted margin.fig';
saveas(gcf,filename); 
%legend('k=10','k=20','k=100');

%%

numExperiments = 10;
K = 20;
numInstancesPerClass = 500;
numIterations = 50;

l20  = avg_experiment(numExperiments, K,  20, ...
                   numInstancesPerClass, numIterations);
l50  = avg_experiment(numExperiments, K,  50, ...
                   numInstancesPerClass, numIterations);
l100 = avg_experiment(numExperiments, K, 100, ...
                   numInstancesPerClass, numIterations);

%%
t = ['effect of nuber of labeled vertices.'...
     ' numExperiments = ' num2str(numExperiments)...
     ', K = ' num2str(K)];
figure('name', t);
subplot(2,1,1);
hold on;
plot(l20.accumulativeLoss,  'r');
plot(l50.accumulativeLoss,  'g');
plot(l100.accumulativeLoss,  'b');
title('accumulative loss sorted by confidence');
legend('#labeled=20','#labeled=50','#labeled=100');
subplot(2,1,2);
hold on;
plot(l20.sortedConfidence,  'r');
plot(l50.sortedConfidence,  'g');
plot(l100.sortedConfidence,  'b');
title('sorted confidence');
legend('#labeled=20','#labeled=50','#labeled=100');

