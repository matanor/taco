classdef LabeledSelector
    %LABELEDSELECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_graph;
    end
    
methods  
    %% Constructor
    
    function this = LabeledSelector(graph)
        this.m_graph = graph;
    end
    
    %% select
    
    function R = select( this, selectBalanced, fromVertices , ...
                         numRequired)
        if (selectBalanced)
            numAvailableLabels = this.m_graph.numAvailableLabels();
            numLabeledPerClass = numRequired / numAvailableLabels;
            if numLabeledPerClass ~= floor(numLabeledPerClass)
                Logger.log(['LabeledSelector.select::Warning. ' ...
                            'numLabeledPerClass (' num2str(numLabeledPerClass) ...
                            ') is not an integer, setting to ' ...
                            num2str(floor(numLabeledPerClass))]);
                numLabeledPerClass = floor(numLabeledPerClass);
            end
            R = this.selectLabelsUniformly...
                (   fromVertices, numLabeledPerClass);
        else
            R = this.selectLabeled_atLeastOnePerLabel...
                (   fromVertices, numRequired); 
        end
    end
    
    %% selectLabeled_atLeastOnePerLabel
    
    function labeled = selectLabeled_atLeastOnePerLabel...
            ( this, vertices, numRequired )
        % 
        labeled = zeros( numRequired, 1);
        selected_i = 1;
        
        % get correct labels for the vertices we select from.
        vertices_correctLabel = this.m_graph.correctLabelsForVertices( vertices );
        
        % select at least one labeled vertex from each class.
        availableLabelsRange = this.m_graph.availableLabels();
        for label_i=availableLabelsRange
            verticesForCurrentLabel = vertices(vertices_correctLabel == label_i);
            numVerticesForCurrentLabel = length(verticesForCurrentLabel);
            labeledVertexPosition = unidrnd(numVerticesForCurrentLabel);
            labeledVertex = verticesForCurrentLabel(labeledVertexPosition);
            labeled( selected_i ) = labeledVertex;
            selected_i = selected_i + 1;
        end
        
        numVertices = length(vertices);
        % select the rest of the labels.
        while( selected_i <= numRequired)
            rnd = unidrnd(numVertices);
            vertex_to_add = vertices(rnd);
            isAlreadySelected = ismember(vertex_to_add, labeled);
            if ( ~isAlreadySelected )
                labeled(selected_i) = vertex_to_add;
                selected_i = selected_i + 1;
            end
        end
    end
    
    %% selectLabelsUniformly
    % Select labeled vertices, the same amount of labled vertices for
    % each class
    % Result: R is a column vector containing index of labeled
    % vertices.    
    
    function R = selectLabelsUniformly(this, vertices, numLabeledPerClass)
        % get correct labels for the vertices we select from.
        vertices_correctLabel = this.m_graph.correctLabelsForVertices( vertices );
        
        availableLabelsRange = this.m_graph.availableLabels();
        labeled = [];
        for label_i = availableLabelsRange
            selected_indices = LabeledSelector.randomSelectWithValue...
                (vertices_correctLabel, numLabeledPerClass, label_i);
            labeled = [labeled; vertices(selected_indices).']; %#ok<AGROW>
        end
        R = labeled;
    end
end

methods (Static)
    %% randomSelectWithValue
    
    function selectedIndices = randomSelectWithValue(data, required, requiredValue)
    % RANDOMSELECTWITHVALUE eandomly select data items with a specific value.
    %   data                - data items.
    %   numRequired         - number of items to select.
    %   requiredValue       - select only from items with this value.

        indicesWithRequiredValue = find(data == requiredValue);
        numFound = length(indicesWithRequiredValue);
        permuted = randperm(numFound);
        selected = permuted(1:required);
        selectedIndices = indicesWithRequiredValue(selected);
    end
end
    
end

