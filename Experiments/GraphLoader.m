classdef GraphLoader
    %GRAPPHLOADER A class for loading graphs from the disk.
    %   Detailed explanation goes here
    
properties (Constant)
	%% index positions in the class to label map
	CLASS_VALUE = 1;
    LABEL_VALUE = 2;
end
    
methods (Static)
    
    %% loadAll
    
    function outGraph = loadAll(graphFileName)
        fileData = load( graphFileName, 'graph' );
        graph = fileData.graph;
        numLabels = length(graph.labels);
        numVertices = size(graph.weights, 1);
        if ( numLabels ~= numVertices)
            verticesToRemove = (numLabels+1):numVertices;
            graph.weights(verticesToRemove,:) = [];
            graph.weights(:,verticesToRemove) = [];
        end
        outGraph = graph;
    end
    
    %% split
    
    function outFolds = split(graph, numFolds)
        numVertices = length(graph.labels);
        outFolds = GraphLoader.randomSplit( 1:numVertices, numFolds );
    end
    
    %% splitBalanced
    
    function outFolds = splitBalanced(graph, numFolds)
        availabelLabels = unique(graph.labels).';
        folds = [];
        %allDiscarded = [];
        for currentLabel = availabelLabels;
            verticesForCurrentLabel = find(graph.labels == currentLabel);
            foldsPerLabel = GraphLoader.randomSplit...
                ( verticesForCurrentLabel, numFolds ); %#ok<FNDSB>
            folds = [folds foldsPerLabel]; %#ok<AGROW>
            %allDiscarded = [allDiscarded;discarded]; %#ok<AGROW>
            %folds = horzcat(folds, foldsPerLabel); 
        end
        outFolds = folds;
    end
    
    %% randomSplit
    
    function folds = randomSplit( data, numGroups )
        dataSize    = numel(data);                      %# get number of elements
        groupSize   = floor(dataSize/numGroups);       %# assuming here that it's neatly divisible 
        tailSize    = mod(dataSize,numGroups);
        % maybe do something with the tail
        % discarded   = data( end-tailSize +1:end );
        withoutTail = data(1:end-tailSize);
        permuted    = withoutTail(randperm(length(withoutTail)));
        folds       = reshape(permuted, numGroups, groupSize);
        groupsOrder = randperm(numGroups);
        folds       = folds(groupsOrder,:);
    end    
    
    %% load
    
    function [ outGraph, labeled ] = load...
            (   graphFileName       , classToLabelMap, ...
                numLabeledPerClass  , numInstancesPerClass )
        %LOADGRAPH Load a graph from disk.

        graph = load( graphFileName, 'graph' );
        graph = graph.graph;

        % select only required classes
        requiredClasses     = classToLabelMap(:, GraphLoader.CLASS_VALUE);
        [selected]          = GraphLoader.selectClasses(graph, requiredClasses);
        
        % Translate class values to label values (e.g. class 1 -> 1, class 2 -> -1)
        numRequiredClasses  = length( requiredClasses );
        for class_i = 1:numRequiredClasses
            classValue = classToLabelMap(class_i, GraphLoader.CLASS_VALUE);
            labelValue = classToLabelMap(class_i, GraphLoader.LABEL_VALUE);
            selected.labels(selected.labels == classValue) = labelValue;
        end

        % Balance the classes
        if numInstancesPerClass ~= 0
            balanced = balanceClasses(selected, numInstancesPerClass);
        else
            balanced = selected;
        end;

        % Randomly select labeled vertices - the same amount
        %  of labeled vertices from each class.

        labeled = GraphLoader.selectLabelsUniformly...
            (  balanced.labels,     classToLabelMap, ...
               numLabeledPerClass);
        % return the labeled vertices in a single column vector.
        labeled = labeled(:);

        % save results in output.

        outGraph = balanced;

    end
    
    %% selectLabeled_atLeastOnePerLabel
    
    function lebeledVertices = selectLabeled_atLeastOnePerLabel...
            ( vertices, correctLabels, classToLabelMap, numRequired )
        %% 
        lebeledVertices = zeros( numRequired, 1);
        selected_i = 1;
        
        % get correct labels for the vertices we select from.
        vertices_correctLabel = correctLabels(vertices);
        
        % select at least one labeled vertex from each class.
        numClasses = size(classToLabelMap,1);
        for class_i=1:numClasses
            labelValue = classToLabelMap(class_i, GraphLoader.LABEL_VALUE);
            verticesForCurrentLabel = vertices(vertices_correctLabel == labelValue);
            numVerticesForCurrentLabel = length(verticesForCurrentLabel);
            labeledVertexPosition = unidrnd(numVerticesForCurrentLabel);
            labeledVertex = verticesForCurrentLabel(labeledVertexPosition);
            lebeledVertices( selected_i ) = labeledVertex;
            selected_i = selected_i + 1;
        end
        
        numVertices = length(vertices);
        % select the rest of the labels.
        while( selected_i <= numRequired)
            rnd = unidrnd(numVertices);
            vertex_to_add = vertices(rnd);
            isAlreadySelected = ismember(vertex_to_add, lebeledVertices);
            if ( ~isAlreadySelected )
                lebeledVertices(selected_i) = vertex_to_add;
                selected_i = selected_i + 1;
            end
        end
    end
    
    %% selectLabelsUniformly
    
    function R = selectLabelsUniformly(vertices,        correctLabels, ...
                                       classToLabelMap, numLabeledPerClass)
        %% Select labeled vertices, the same amount of labled vertices for
        %  each class
        %  Result: R is a column vector containing index of labeled
        %  vertices.
                
        % get correct labels for the vertices we select from.
        vertices_correctLabel = correctLabels(vertices);
        
        numRequiredClasses = size(classToLabelMap, 1);
        labeled = [];
        for class_i = 1:numRequiredClasses
            labelValue = classToLabelMap(class_i, GraphLoader.LABEL_VALUE);
            selected_indices = GraphLoader.randomSelectWithValue...
                (vertices_correctLabel, numLabeledPerClass, labelValue);
            labeled = [labeled; vertices(selected_indices).']; %#ok<AGROW>
        end
        R = labeled;
    end

    %% randomSelectWithValue
    
    function selectedIndices = randomSelectWithValue(data, required, requiredValue)
    % RANDOMSELECTWITHVALUE eandomly select data items with a specific value.
    %   data                - data items.
    %   numRequired         - number of items to select.
    %   requiredValue       - select onlt from items with this value.

        indicesWithRequiredValue = find(data == requiredValue);
        numFound = length(indicesWithRequiredValue);
        permuted = randperm(numFound);
        selected = permuted(1:required);
        selectedIndices = indicesWithRequiredValue(selected);
    end
    
    %% SELECTCLASSES
    
    function selected = selectClasses(graph, requiredLabels)
        % SELECTCLASSES Select only nodes with specific labels from the graph.
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

