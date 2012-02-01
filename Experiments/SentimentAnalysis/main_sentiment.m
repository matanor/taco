
%% Load the graph
load sentiment_10k;

%% Balance the classes
numInstancesPerClass = 1000;
[balanced.weights, balanced.labels ] = ...
    balanceClasses(sentiment_10k.weights,sentiment_10k.labels,...
    numInstancesPerClass);

isSymetric(balanced.weights);

%% 

w = balanced.weights;

%%

classLabelMap = [ 1 -2;
                  2 -1;
                  3  0;
                  4 +1;
                  5 +2 ];
CLASS = 1;
LABEL_VALUE = 2;

lbls = zeros( size(balanced.labels) );
numClasses = size( classLabelMap, CLASS );
for class_i=1:numClasses
    labelValue = classLabelMap(class_i, LABEL_VALUE);
    classValue = classLabelMap(class_i, CLASS);
    lbls( balanced.labels == classValue ) = labelValue;
end

%lbls = lbls - 3;

%% Create K-Nearest Neighbour graph
K = 20;
w_nn = knn(w,K);

%% Randomly select labeled vertices
numLabeled = 200;
labeledPositive = selectLabeled(lbls, numLabeled, +2);
labeledNegative = selectLabeled(lbls, numLabeled, -2);
%labeledPositive = unidrnd(1000, numLabeled, 1) + 3000;
%labeledNegative = unidrnd(1000, numLabeled, 1) + 2000;

%% Prepare parameters
num_iterations = 30;
positiveInitialValue = +2;
negativeInitialValue = -2;
labeledConfidence = 0.1;
alpha = 1;
beta = 1;

%% Run the algorithm
result = confidenceSSL...
    ( w_nn, num_iterations, labeledPositive, labeledNegative, ...
        positiveInitialValue,negativeInitialValue, ...
        labeledConfidence, alpha, beta);
    
%% Show final prediction & confidence
numVertices = size( result.mu, 1);
% 
% figure;
% hold on;
% scatter(1:numVertices, result.mu(:,num_iterations));
% plot(lbls);
% title('mu (prediction)');
% hold off;
% 
% figure;
% scatter(1:numVertices, result.v (:,num_iterations));
% title('v (confidence)');
% 
%% Quantize the prediction to the discrete classes
numClasses = length(unique(balanced.labels));
%range = linspace(negativeInitialValue, ...
%                 positiveInitialValue, numClasses + 1);
range = [-2.5 -1.5 -0.5 0.5 1.5 2.5];
final_mu = result.mu(:,num_iterations);     
prediction = final_mu;
for range_i = 1:numClasses
    bottom = range(range_i);
    top = range(range_i + 1);
    labelValue = classLabelMap(range_i, LABEL_VALUE);
    prediction(bottom <= prediction & prediction < top) ...
        = labelValue;
        
        %range_i - 3;
end

%%
%scatter(1:numVertices,prediction);
correct = (prediction == lbls);
margin = abs( lbls - final_mu );

%%
final_confidence = result.v(:,30);
[sortedConfidence,confidenceSortIndex] = sort(final_confidence);
correctSortedAccordingToConfidence = ...
    correct(confidenceSortIndex);
marginSortedAccordingToConfidence = margin(confidenceSortIndex);
wrong = 1 - correctSortedAccordingToConfidence;
accumulativeLoss = cumsum(wrong);
%%
figure;
subplot(3,1,1);
plot(accumulativeLoss);
title('accumulative loss sorted by confidence');
subplot(3,1,2);
plot(sortedConfidence);
title('sorted confidence');
subplot(3,1,3);
scatter(1:length(marginSortedAccordingToConfidence), ...
        marginSortedAccordingToConfidence );
title('margin sorted according to confidence ');

%% 

for class_i=1:numClasses
    labelValue = classLabelMap(class_i, LABEL_VALUE);
    classValue = classLabelMap(class_i, CLASS);
    class_vertices_indices = find( lbls == labelValue);
    class_labels = lbls(class_vertices_indices);
    class_mu = final_mu( class_vertices_indices );
    class_margin = abs( class_mu - class_labels);
    class_confidence = final_confidence(class_vertices_indices);
    class_isCorrect = correct(class_vertices_indices);
    showResult_byConfidence...
        (class_confidence, class_mu, ...
         class_margin    , class_isCorrect, ...
         classValue      , labelValue);
end

