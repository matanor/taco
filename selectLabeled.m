function selectedIndices = selectLabeled...
    (labels, numRequired, withRequiredValue)
%SELECTLABELED select labels vertices from a list of all labels
%   labeles - a vector of labels
%   numRequired - number of labels required.
%   withRequiredValue - find labels with this value.

    idx = find(labels == withRequiredValue);
    numFound = length(idx);
    selected_i = 1;
    selected = zeros(numRequired, 1);
    while( selected_i <= numRequired)
        rnd = unidrnd(numFound);
        isAlreadySelected = ismember(rnd, selected);
        if ( ~isAlreadySelected )
            selected(selected_i) = rnd;
            selected_i = selected_i + 1;
        end
    end
    selectedIndices = idx(selected);
    selectedIndices = unique(selectedIndices);
end

