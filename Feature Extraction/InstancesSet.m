classdef InstancesSet < handle
    %INSTANCESSET Summary of this class goes here
    %   Detailed explanation goes here
    
properties (Access = public)
    m_stringToFeatureNumberMap;
    m_stringToLabelNumberMap;
    m_instances;
    m_tfidf;
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
        this.m_tfidf = sparse(1);
    end
    
    %% instances
    
    function R = instances(this)
        R = this.m_instances;
    end
    
    %% tfidf
    
    function R = tfidf(this)
        R = this.m_tfidf;
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
    
    %% create_tfidf
    
    function create_tfidf(this)
        Logger.log('Creating tfidf features...');
        numDocuments = this.numInstances();
        numDocumentsPerFeature = sum(this.m_instances ~=0,1); % row vector
        numWordsPerInstance = sum(this.m_instances,2); % column vector
        numFeatures = this.numFeatures();
        this.m_tfidf = sparse(numDocuments,numFeatures);
        for feature_i=1:numFeatures
            for instance_i=1:numDocuments
                if this.m_instances(instance_i,feature_i) ~=0
                    tf = this.m_instances(instance_i,feature_i) ./ ...
                              numWordsPerInstance(instance_i); 
                    idf = log( numDocuments ./ ...
                               numDocumentsPerFeature(feature_i));
                    this.m_tfidf(instance_i,feature_i) = tf * idf;
                    clear tf idf;
                end
            end
            if mod(feature_i,1000) == 0
                Logger.log(['Progress: ' num2str(feature_i) ...
                            ' features, out of ' num2str(numFeatures)]);
            end
        end
        Logger.log('Finished tfidf features.');
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

