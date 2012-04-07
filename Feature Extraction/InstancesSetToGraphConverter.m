classdef InstancesSetToGraphConverter
    %INSTANCESSETTOGRAPHCONVERTER Summary of this class goes here
    %   Detailed explanation goes here
    
properties
end
    
methods (Static)
    function graph = convert(instancesSet, use_tfidf)
        Logger.log(['Converting instances to graph. ' ...
                    'use_tfidf = ' num2str(use_tfidf)]);
        if use_tfidf
            instances = instancesSet.tfidf();
        else
            instances = instancesSet.instances();
        end
        norm_l2 = full(sqrt(sum(instances.^2,2)));
        norm_ij = norm_l2 * norm_l2.';
        weights = (instances  * instances.') ./ norm_ij;
        weights = zeroMainDiagonal(weights);
        graph.weights = full(weights);
        
        labels = instancesSet.labels();
        graph.labels = labels;
        
        if use_tfidf
            graph.name = [instancesSet.name() '.tfidf'];
        else
            graph.name = instancesSet.name();
        end
    end
end
    
end

