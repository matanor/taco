rootFolder = 'C:\technion\theses\Experiments\timit\features_39_cms_white\trainAndTest';

distancesFile = [rootFolder '\trainAndTest_cms_white.context7.k_10.mat'];
featuresFile  = [rootFolder '\trainAndTest_cms_white.context7.mat'];

%% 
load(distancesFile);
k10 = max(graph.distances,[],2);
graph.distances = graph.distances.';
numCols = size(graph.distances,2);
med = zeros(numCols,1);
for col_i=1:numCols
    if mod(col_i, 10000) == 0
        Logger.log(['col_i = ' num2str(col_i)]);
    end
    [~, ~, col_values] = find(graph.distances(:,col_i));
    med(col_i) = sqrt(median(col_values));
end
clear graph;

%% 
load(featuresFile);
trueLabel = graph.phoneids39;
clear graph;

for class_i=1:39
    x = k10(trueLabel == class_i);
    classMedian(class_i) = median(sqrt(x));
    classMean(class_i) = mean(sqrt(x));
end

%%

figure('name','histogram of median of 10 th neighbour, per class');
hist(classMedian);

%%

figure('name','median of 10 nearest neighbours histogram');
hist(med,50);
yL = get(gca,'YLim');
%line([3 3],yL,'Color','r');

