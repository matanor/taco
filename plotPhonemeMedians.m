rootFolder = 'C:\technion\theses\Experiments\timit\features_39\trainAndTest';

distancesFile = [rootFolder '\trainAndTest_notWhite.context7.k_10.mat'];
featuresFile  = [rootFolder '\trainAndTest_notWhite.context7.mat'];

load(distancesFile);
k10 = max(graph.distances,[],2);
clear graph;

load(featuresFile);
trueLabel = graph.phoneids39;
clear graph;

for class_i=1:39
    x = k10(trueLabel == class_i);
    classMedian(class_i) = median(sqrt(x));
    classMean(class_i) = mean(sqrt(x));
end