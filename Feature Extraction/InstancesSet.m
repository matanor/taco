classdef InstancesSet < handle
    %INSTANCESSET Summary of this class goes here
    %   Detailed explanation goes here
    
properties (Access = public)
    m_stringToFeatureNumberMap;
    m_stringToLabelNumberMap;
    m_instances;
    m_labels;
    m_name;
end

methods (Access = public)
    
    %% Constructor
    
    function this = InstancesSet()
        this.m_stringToFeatureNumberMap = containers.Map;
        this.m_stringToLabelNumberMap = containers.Map;
        this.m_instances = sparse(1);
        this.m_labels = [];
    end
    
    %% instances
    
    function R = instances(this)
        R = this.m_instances;
    end
    
    %% labels
    % returns a column vector of numeric labels
    function R = labels(this)
        R = this.m_labels.';
    end
    
    %% name
    
    function R = name(this)
        R = this.m_name;
    end
    
    %% set_name
    
    function set_name(this, value)
        this.m_name = value;
    end
    
    %% numFeatures
    
    function R = numFeatures(this)
        R = size(this.m_instances,2);
    end
    
    %% numInstances
    
    function R = numInstances(this)
        R = size(this.m_instances,1);
    end
    
    %% labelNameToLabelNumber
    
    function R = labelNameToLabelNumber(this, labelName)
        R = this.translateNameToNumber...
            (this.m_stringToLabelNumberMap, labelName);
    end 
    
    %% featureNameToFeatureNumber
    
    function R = featureNameToFeatureNumber(this, featureName)
        R = this.translateNameToNumber...
            (this.m_stringToFeatureNumberMap, featureName);
    end
    
    %% addFeatureToInstance
    
    function addFeatureToInstance(this, instance_i, featureNumber, featureValue)
        if instance_i <= this.numInstances() && ...
           featureNumber <= this.numFeatures()
            currentFeatureValue = this.m_instances(instance_i, featureNumber);
        else
            currentFeatureValue = 0;
        end
        newFeatureValue = currentFeatureValue + featureValue;
        this.m_instances(instance_i, featureNumber) = newFeatureValue;
    end
    
    %% setLabelForInstance
    
    function setLabelForInstance(this, instance_i, labelNumber)
        this.m_labels(instance_i) = labelNumber;
    end
    
    %% writeLabelMapping
    
    function writeLabelMapping(this, outputFileName)
        keys = this.m_stringToLabelNumberMap.keys;
        allMapping = [];
        for key_i=keys
            key_as_matrix = cell2mat(key_i);
            value = this.m_stringToLabelNumberMap(key_as_matrix);
            mapping.key = key_as_matrix;
            mapping.value = value;
            allMapping = [allMapping; mapping]; %#ok<AGROW>
        end
        
        [~, order] = sort([allMapping(:).value]);
        allMapping = allMapping(order);
        
        outputFileID = fopen(outputFileName, 'w');
        for mapping_i=1:length(allMapping)
            fprintf(outputFileID, '%s -> %s\n', ...
                    allMapping(mapping_i).key, ...
                    num2str(allMapping(mapping_i).value));
        end
        fclose(outputFileID);
    end
    
end

methods (Static)
    
    %% translateNameToNumber
    
    function R= translateNameToNumber(map, key)
        if map.isKey(key)
            R = map(key);
        else
            % a new feature
            newMappedNumber = uint32(map.Count) + 1;
            map(key) = newMappedNumber; %#ok<NASGU>
            R = newMappedNumber ;
        end
    end
end
    
end

