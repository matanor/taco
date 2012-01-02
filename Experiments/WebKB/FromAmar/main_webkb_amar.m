%% Prepare common params

constructionParams.numLabeled = 50;
constructionParams.numInstancesPerClass = 500;

algorithmParams.numIterations = 50;
algorithmParams.labeledConfidence = 0.1;
algorithmParams.alpha = 1;
algorithmParams.beta = 1;

numExperiments = 1;
showResults = 1;

graphFileName = 'C:\technion\theses\Experiments\WebKB\data\From Amar\webkb_amar.mat';

%% Run different values of k

constructionParams.K = 10;
k10.exp  = run_multiple_experiments ...
        (graphFileName, numExperiments, ...
         constructionParams, algorithmParams);

constructionParams.K = 20;
k20.exp  = run_multiple_experiments ...
        (graphFileName, numExperiments, ...
         constructionParams, algorithmParams);

constructionParams.K = 100;
k100.exp  = run_multiple_experiments ...
        (graphFileName, numExperiments, ...
         constructionParams, algorithmParams);

%%
     
k10.analyzed  = analyzeResults( k10.exp.experimentsOutput(1) );
k20.analyzed  = analyzeResults( k20.exp.experimentsOutput(1) );
k100.analyzed = analyzeResults( k100.exp.experimentsOutput(1) );

%% Compare K
numLabeled = constructionParams.numLabeled;
numRows = 2;
numCols = 1;

t = ['effect of K-nn graph.'...
     ' numExperiments = '   num2str(numExperiments)...
     ', numLabeled = '      num2str(numLabeled)];
figure('name', t);
subplot(numRows,numCols,1);
hold on;

plot(k10.analyzed.sorted.by_confidence.accumulative,  'r');
plot(k20.analyzed.sorted.by_confidence.accumulative,  'g');
plot(k100.analyzed.sorted.by_confidence.accumulative,  'b');
title('accumulative loss sorted by confidence');
legend('k=10','k=20','k=100');
subplot(numRows,numCols,2);
hold on;
plot(k10.analyzed.sorted.by_confidence.confidence,  'r');
plot(k20.analyzed.sorted.by_confidence.confidence,  'g');
plot(k100.analyzed.sorted.by_confidence.confidence,  'b');
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

l20  = run_multiple_experiments(numExperiments, K,  20, ...
                   numInstancesPerClass, numIterations);
l50  = run_multiple_experiments(numExperiments, K,  50, ...
                   numInstancesPerClass, numIterations);
l100 = run_multiple_experiments(numExperiments, K, 100, ...
                   numInstancesPerClass, numIterations);

%%
t = ['effect of nuber of labeled vertices.'...
     ' numExperiments = ' num2str(numExperiments)...
     ', K = ' num2str(K)];
figure('name', t);
subplot(2,1,1);
hold on;
plot(l20.sortedAccumulativeLoss,  'r');
plot(l50.sortedAccumulativeLoss,  'g');
plot(l100.sortedAccumulativeLoss,  'b');
title('accumulative loss sorted by confidence');
legend('#labeled=20','#labeled=50','#labeled=100');
subplot(2,1,2);
hold on;
plot(l20.sortedConfidence,  'r');
plot(l50.sortedConfidence,  'g');
plot(l100.sortedConfidence,  'b');
title('sorted confidence');
legend('#labeled=20','#labeled=50','#labeled=100');

