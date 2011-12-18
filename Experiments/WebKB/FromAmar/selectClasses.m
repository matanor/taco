function selected = selectClasses(graph, requiredLabels)
%SELECTCLASSES Summary of this function goes here
%   Detailed explanation goes here

w = graph.weights;
l = graph.labels;

%[~, requiredIndices] = ismember(requiredLabels, l);

requiredIndices = [];
for label_i=1:length(l)
    label = l(label_i);
    if ismember(label,requiredLabels)
        requiredIndices = [requiredIndices; label_i];
    end
end
%[~, requiredIndexes, ~] = intersect(l, requiredLabels);

selected.labels = l(requiredIndices);
selected.weights = w(requiredIndices, requiredIndices);

end

