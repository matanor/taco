classdef GraphLoader
    %GRAPPHLOADER A class for loading graphs from the disk.
    %   Detailed explanation goes here
    
properties (Constant)
	%% index positions in the class to label map
	CLASS_VALUE = 1;
    LABEL_VALUE = 2;
end
    
methods (Static)
    function outGraph = loadAll(graphFileName)
        fileData = load( graphFileName, 'graph' );
        outGraph = fileData.graph;
    end
    
    function outFolds = split(graph, numFolds)
        availabelLabels = unique(graph.labels).';
        folds = [];
        for currentLabel = availabelLabels;
            verticesForCurrentLabel = find(graph.labels == currentLabel);
            foldsPerLabel = GraphLoader.randomSplit( verticesForCurrentLabel, numFolds ); %#ok<FNDSB>
            folds = [folds foldsPerLabel]; %#ok<AGROW>
            %folds = horzcat(folds, foldsPerLabel); 
        end
        outFolds = folds;
    end
    
    function folds = randomSplit( data, numGroups )
        dataSize    = numel(data);                      %# get number of elements
        groupSize   = floor(dataSize/numGroups);       %# assuming here that it's neatly divisible 
        tailSize    = mod(dataSize,numGroups);
        % maybe do something with the tail
        % tail        = data( end-tailSize +1:end );
        withoutTail = data(1:end-tailSize);
        permuted    = withoutTail(randperm(length(withoutTail)));
        folds       = reshape(permuted, numGroups, groupSize);
        groupsOrder = randperm(numGroups);
        folds       = folds(groupsOrder,:);
    end    
    
    function [ outGraph, labeled ] = load...
            (   graphFileName       , classToLabelMap, ...
                numLabeledPerClass  , numInstancesPerClass )
        %LOADGRAPH Load a graph from disk.

        %% Load the graph

        graph = load( graphFileName, 'graph' );
        graph = graph.graph;

        %% select only required classes
        requiredClasses     = classToLabelMap(:, GraphLoader.CLASS_VALUE);
        [selected]          = GraphLoader.selectClasses(graph, requiredClasses);
        %% Translate class values to label values (e.g. class 1 -> 1, class 2 -> -1)
        numRequiredClasses  = length( requiredClasses );
        for class_i = 1:numRequiredClasses
            classValue = classToLabelMap(class_i, GraphLoader.CLASS_VALUE);
            labelValue = classToLabelMap(class_i, GraphLoader.LABEL_VALUE);
            selected.labels(selected.labels == classValue) = labelValue;
        end

        %% Balance the classes
        if numInstancesPerClass ~= 0
            balanced = balanceClasses(selected, numInstancesPerClass);
        else
            balanced = selected;
        end;

        %% Randomly select labeled vertices - the same amount
        %  of labeled vertices from each class.

        labeled = GraphLoader.selectLabelsUniformly...
            (  balanced.labels,     classToLabelMap, ...
               numLabeledPerClass,  numRequiredClasses);
        % return the labeled vertices in a single column vector.
        labeled = labeled(:);

        %% save results in output.

        outGraph = balanced;

    end
    
    function selected = selectLabeled_atLeastOnePerLabel( labels, classToLabelMap, numRequired )
        selected = zeros( numRequiredLabeles, 1);
        selected_i = 1;
        numVertices = length(labels);
        
        %% select at least one labeled vertex from each class.
        numClasses = size(classToLabelMap,1);
        for class_i=1:numClasses
            labelValue = classToLabelMap(class_i, GraphLoader.LABEL_VALUE);
            verticesForCurrentLabel = find(labels == labelValue);
            numVerticesForCurrentLabel = length(verticesForCurrentLabels);
            labeledVertexPosition = unidrnd(numVerticesForCurrentLabel);
            labeledVertex = verticesForCurrentLabel(labeledVertexPosition);
            selected( selected_i ) = labeledVertex;
            selected_i = selected_i + 1;
        end
        
        %% select the rest of the labels.
        while( selected_i <= numRequired)
            rnd = unidrnd(numVertices);
            isAlreadySelected = ismember(rnd, selected);
            if ( ~isAlreadySelected )
                selected(selected_i) = rnd;
                selected_i = selected_i + 1;
            end
        end
    end
    
    function R = selectLabelsUniformly(labels, classToLabelMap, numLabeledPerClass, numRequiredClasses)
        %% Select labeled vertices, the same amount of labled vertices for
        %  each class
        %  Result: R is a numLabeledPerClass X numRequiredClasses matrix.
        %          each column contains the labeled vertices for a single
        %          class.
        labeled = zeros(numLabeledPerClass, numRequiredClasses);
        for class_i = 1:numRequiredClasses
            labelValue = classToLabelMap(class_i, GraphLoader.LABEL_VALUE);
            labeled(:, class_i) = ...
                    GraphLoader.randomSelectWithValue(labels, numLabeledPerClass, labelValue);
        end
        R = labeled;
    end

    function selectedIndices = randomSelectWithValue(data, required, requiredValue)
    %SELECTLABELED eandomly select data items with a specific value.
    %   data                - data items.
    %   numRequired         - number of items to select.
    %   requiredValue       - select onlt from items with this value.

        indicesWithRequiredValue = find(data == requiredValue);
        numFound = length(indicesWithRequiredValue);
        permuted = randperm(numFound);
        selected = permuted(1:required);
        selectedIndices = indicesWithRequiredValue(selected);
    end
    
    function selected = selectClasses(graph, requiredLabels)
        %SELECTCLASSES Select only nodes with specific labels from the graph.
        % graph - the graph structure:
        %           weigths - weights matrix
        %           labels  - vector
        % requiredLabeles - a vector containing the labels
        %                   to select

        w = graph.weights;
        l = graph.labels;

        requiredIndices = [];
        for label_i=1:length(l)
            label = l(label_i);
            if ismember(label,requiredLabels)
                requiredIndices = [requiredIndices; label_i]; %#ok<AGROW>
            end
        end

        selected.labels = l(requiredIndices);
        selected.weights = w(requiredIndices, requiredIndices);
    end

end % methods (Static)
    
end % classdef

