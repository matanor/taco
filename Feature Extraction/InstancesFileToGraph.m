classdef InstancesFileToGraph
    %INSTANCESFILETOGRAPHCONVERTER Summary of this class goes here
    %   Detailed explanation goes here
    
methods (Static)
    
    %% textDataSets
    
    function R = textDataSets()
        dataset_i = 1;
        
        rootDir = 'C:/technion/theses/Experiments/';
        
        R(dataset_i).fileName = [rootDir 'enron/farmer-d.instances'];
        R(dataset_i).maxInstances = DefaultFormatReader.READ_ALL_INSTANCES;
        dataset_i = dataset_i + 1;
        
        R(dataset_i).fileName = [rootDir 'enron/kaminski-v.instances'];
        R(dataset_i).maxInstances = DefaultFormatReader.READ_ALL_INSTANCES;
        dataset_i = dataset_i + 1; %#ok<NASGU>
        
%         R{dataset_i} = 'C:\technion\theses\Experiments\20news\From Koby\all.instances';
%         dataset_i = dataset_i + 1;

%         R(dataset_i).fileName = [rootDir 'sentiment/all.instances'];
%         R(dataset_i).maxInstances = DefaultFormatReader.READ_ALL_INSTANCES;
%         dataset_i = dataset_i + 1;
%         
%         R(dataset_i).fileName = [rootDir 'sentiment/books_dvd_music.instances'];
%         R(dataset_i).maxInstances = 7000;
%         dataset_i = dataset_i + 1;
%         
%         R(dataset_i).fileName = [rootDir 'reuters\reuters_4_topics.instances'];
%         R(dataset_i).maxInstances = 4000;
%         dataset_i = dataset_i + 1;
        
    end
    
    %% runOnAllTextDatasets
    
    function runOnAllTextDatasets()
        InstancesFileToGraph.runOnDatasets( InstancesFileToGraph.textDataSets);
    end
    
    %% runOnDatasets
    
    function runOnDatasets( datasets )
        numDataSets = length(datasets);
        for dataset_i=1:numDataSets
            currentDataset = datasets(dataset_i);
            Logger.log(['File Name = '''   currentDataset.fileName '''']);
            Logger.log(['Max instances = ' num2str(currentDataset.maxInstances) ]);
            InstancesFileToGraph.runOnSingleDataset...
            ( currentDataset.fileName, currentDataset.maxInstances );
        end
    end
    
    %% runOnSingleDataset
    
    function runOnSingleDataset(fileName, maxInstances)
        reader = DefaultFormatReader(fileName);
        [path, name, ~]  = fileparts(fileName);
        reader.init();
        reader.read(maxInstances);
        reader.close();
        
        instancesSet = reader.instancesSet();
        labelMappingFileName = [path '/' name '.labels.mapping.txt'];
        instancesSet.writeLabelMapping(labelMappingFileName);
        instancesFileName = [path '/' name '.mat'];
        save(instancesFileName, 'instancesSet');
        
        graph = InstancesSetToGraphConverter.convert( instancesSet ); %#ok<NASGU>
        graphFileName = [path '/' name '.graph.mat'];
        save(graphFileName, 'graph');
    end
end
    
end

