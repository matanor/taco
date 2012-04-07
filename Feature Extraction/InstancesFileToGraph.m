classdef InstancesFileToGraph
    %INSTANCESFILETOGRAPHCONVERTER Summary of this class goes here
    %   Detailed explanation goes here
    
methods (Static)
    
    %% textDataSets
    
    function R = textDataSets(isOnOdin)
        dataset_i = 1;
        
        if isOnOdin
            rootDir = '/u/matanorb/experiments/';
        else
            rootDir = 'C:/technion/theses/Experiments/';            
        end
        
        R(dataset_i).fileName = [rootDir 'enron/farmer-d.instances'];
        R(dataset_i).maxInstances = DefaultFormatReader.READ_ALL_INSTANCES;
        dataset_i = dataset_i + 1;
        
        R(dataset_i).fileName = [rootDir 'enron/kaminski-v.instances'];
        R(dataset_i).maxInstances = DefaultFormatReader.READ_ALL_INSTANCES;
        dataset_i = dataset_i + 1; %#ok<NASGU>
        
%         R{dataset_i} = 'C:\technion\theses\Experiments\20news\From Koby\all.instances';
%         dataset_i = dataset_i + 1;

        R(dataset_i).fileName = [rootDir 'amazon/all.instances'];
        R(dataset_i).maxInstances = DefaultFormatReader.READ_ALL_INSTANCES;
        dataset_i = dataset_i + 1;
        
        R(dataset_i).fileName = [rootDir 'amazon/books_dvd_music.instances'];
        R(dataset_i).maxInstances = 7000;
        dataset_i = dataset_i + 1;
        
        R(dataset_i).fileName = [rootDir 'reuters/reuters_4_topics.instances'];
        R(dataset_i).maxInstances = 4000;
        dataset_i = dataset_i + 1;
        
    end
    
    %% runOnAllTextDatasets_desktop
    
    function runOnAllTextDatasets_desktop()
        onOdin = 0;
        InstancesFileToGraph.runOnAllTextDatasets( onOdin );
    end
    
    %% runOnAllTextDatasets_odin
    
    function runOnAllTextDatasets_odin()
        onOdin = 1;
        InstancesFileToGraph.runOnAllTextDatasets( onOdin );
    end
    
    %% runOnAllTextDatasets
    
    function runOnAllTextDatasets(isOnOdin)
        InstancesFileToGraph.runOnDatasets...
            ( InstancesFileToGraph.textDataSets(isOnOdin));
    end
    
    %% runOnDatasets
    
    function runOnDatasets( datasets )
        numDataSets = length(datasets);
        for dataset_i=1:numDataSets
            currentDataset = datasets(dataset_i);
            Logger.log(['File Name = '''   currentDataset.fileName '''']);
            Logger.log(['Max instances = ' num2str(currentDataset.maxInstances) ]);
%             InstancesFileToGraph.readInstancesAndCreateGraph...
%                 ( currentDataset.fileName, currentDataset.maxInstances );
            InstancesFileToGraph.createGraphUsingTfidf...
                ( currentDataset.fileName );
        end
    end
    
    %% readInstancesAndCreateGraph
    
    function readInstancesAndCreateGraph(fileName, maxInstances)
        reader = DefaultFormatReader(fileName);
        [path, name, ~]  = fileparts(fileName);
        reader.init();
        reader.read(maxInstances);
        reader.close();
        
        instancesSet = reader.instancesSet();
        labelMappingFileName = [path '/' name '.labels.mapping.txt'];
        instancesSet.writeLabelMapping(labelMappingFileName);
        instancesFileName = [path '/' name '.mat'];
        Logger.log(['Saving instances to ''' instancesFileName '''']);
        save(instancesFileName, 'instancesSet');
        
        use_tfidf = 0;
        graph = InstancesSetToGraphConverter.convert...
            ( instancesSet, use_tfidf  ); %#ok<NASGU>
        graphFileName = [path '/' name '.graph.mat'];
        Logger.log(['Saving graph to ''' graphFileName '''']);
        save(graphFileName, 'graph');       
    end
    
    %% createGraphUsingTfidf
    
    function createGraphUsingTfidf(fileName)
        [path, name, ~]  = fileparts(fileName);
        instancesFileName = [path '/' name '.mat'];
        Logger.log(['Loading instances from ''' instancesFileName '''']);
        inputData = load(instancesFileName);
        instancesSet = inputData.instancesSet;
        
        instancesSet.create_tfidf();
        
        save(instancesFileName, 'instancesSet');
        
        use_tfidf = 1;
        graph = InstancesSetToGraphConverter.convert...
            ( instancesSet, use_tfidf  ); %#ok<NASGU>
        graphFileName = [path '/' name '.tfidf.graph.mat'];
        Logger.log(['Saving tfidf graph to ''' graphFileName '''']);
        save(graphFileName, 'graph');
    end
end
    
end

