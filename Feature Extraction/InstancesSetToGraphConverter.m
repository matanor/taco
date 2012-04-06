classdef InstancesSetToGraphConverter
    %INSTANCESSETTOGRAPHCONVERTER Summary of this class goes here
    %   Detailed explanation goes here
    
properties
end
    
methods (Static)
    function graph = convert(instancesSet)
        instances = instancesSet.instances();
        norm_l2 = full(sqrt(sum(instances.^2,2)));
        norm_ij = norm_l2 * norm_l2.';
        weights = (instances  * instances.') ./ norm_ij;
        weights = zeroMainDiagonal(weights);
        graph.weights = full(weights);
        
        labels = instancesSet.labels();
        graph.labels = labels;
        
        graph.name = instancesSet.name();
    end
end
    
end

