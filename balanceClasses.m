function [ selected ] = balanceClasses...
                        ( graph, numInstancesPerClass )
%BALANCECLASSES Select the same amount of instances from each class.
%   graph - a structure containing the fields:
%       weights - input graph weights.
%       labels  - input graph labels.
%   numInstancesPerClass - required number of instances
%   to select for each class.

weights = graph.weights;
labels = graph.labels;

numClasses = length(unique(labels));

CLASS_VALUE = 1;
COUNT_VALUE = 2;
classToCountMap = zeros( numClasses, 2);
classToCountMap(: , CLASS_VALUE) = unique(labels);
classToCountMap(: , COUNT_VALUE) = 1:numClasses;

numVertices = length(labels);
count = zeros( numClasses, 1) ;
numRequiredIndexes = numClasses * numInstancesPerClass;
selectedIndexes = zeros(numRequiredIndexes ,1);
selected_i = 1;

while( selected_i <= numRequiredIndexes)
    
    idx = unidrnd(numVertices);
    selectedClass = labels(idx);
    
    % find the counter index for the class
    count_i = 0;
    for class_i = 1: numClasses
        if selectedClass == ...
           classToCountMap(class_i, CLASS_VALUE)
            count_i = classToCountMap(class_i, COUNT_VALUE);
            break;
        end
    end
    
    if ( count(count_i) < numInstancesPerClass )
        isAlreadySelected = find(selectedIndexes == idx, 1);
        if ( isempty( isAlreadySelected  ) )
            selectedIndexes(selected_i) = idx;
            selected_i = selected_i + 1;
            count(count_i) = count(count_i) + 1;
        end;
    end;
    
end

selectedIndexes = sort(selectedIndexes);
selected.labels = labels(selectedIndexes);
selected.weights = weights( selectedIndexes, selectedIndexes);
