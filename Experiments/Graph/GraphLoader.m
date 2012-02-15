classdef GraphLoader
    %GRAPPHLOADER A class for loading graphs from the disk.
    %   Detailed explanation goes here
    
properties (Constant)
	%% index positions in the class to label map
	CLASS_VALUE = 1;
    LABEL_VALUE = 2;
end
    
methods (Static)
    
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

