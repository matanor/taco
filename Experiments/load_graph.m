function [ outGraph, labeled ] =...
    load_graph(    graphFileName, classToLabelMap, ...
                        K, numLabeledRequired, numInstancesPerClass )
%LOADAMARGRAPH Summary of this function goes here
%   Detailed explanation goes here

%% index positions in the class to label map

CLASS_VALUE = 1;
LABEL_VALUE = 2;

%% Load the graph

% load 'C:\courses\theses\WebKB\data\From Amar\webkb_amar.mat';
% graph = webkb_amar;
graph = load( graphFileName, 'graph' );
graph = graph.graph;

%% select only required classes
requiredClasses = classToLabelMap(:, CLASS_VALUE);
[selected] = selectClasses(graph, requiredClasses);
numRequiredClasses = length( requiredClasses );
for class_i = 1:numRequiredClasses
    classValue = classToLabelMap(class_i, CLASS_VALUE);
    labelValue = classToLabelMap(class_i, LABEL_VALUE);
    selected.labels(selected.labels == classValue) = labelValue;
end

%% Balance the classes
if numInstancesPerClass ~= 0
    [balanced ] = ...
        balanceClasses(selected, numInstancesPerClass);
else
    balanced = selected;
end;

%isSymetric(balanced.weights);

%% 

w = balanced.weights;
lbls = balanced.labels;

%% Create K-Nearest Neighbour graph

w_nn = knn(w,K);

%% Randomly select labeled vertices

labeled = zeros(numLabeledRequired, numRequiredClasses);
for class_i = 1:numRequiredClasses
    labelValue = classToLabelMap(class_i, LABEL_VALUE);
    labeled(:, class_i) = ...
        selectLabeled(lbls, numLabeledRequired, labelValue);
end

outGraph.weights = w_nn;
outGraph.labels = lbls;

end

