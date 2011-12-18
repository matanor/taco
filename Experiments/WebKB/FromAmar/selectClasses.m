function selected = selectClasses(graph, requiredLabels)
%SELECTCLASSES Select only nodes with specific labels from the graph.
% graph - the graph structure, containing weights matrix
% and labels vector
% requiredLabeles - a vector containing the labels
%                   to select

w = graph.weights;
l = graph.labels;

requiredIndices = [];
for label_i=1:length(l)
    label = l(label_i);
    if ismember(label,requiredLabels)
        requiredIndices = [requiredIndices; label_i];
    end
end

selected.labels = l(requiredIndices);
selected.weights = w(requiredIndices, requiredIndices);

end

