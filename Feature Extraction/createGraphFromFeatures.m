
%% load the feature vectors
load tfidf_sentiment;

%% calculate the graph weights
weights = tfidf * tfidf .';

%% make the weights non-sparse
weights = full(weights);

%% zero the main diagonal - no one vertice loops
weights = zeroMainDiagonal( weights );

imshow(weights,[]);
%% put the weights in the graph
graph.weights = weights;

%% read the labels file
labels = csvread('labels.csv');

%% put labels in the graph
graph.labels = labels;

sentiment_10k = graph;

save 'sentiment_10k.mat' sentiment_10k;