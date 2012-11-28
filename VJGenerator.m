classdef VJGenerator
    %VJGenerator Summary of this class goes here
    %   Detailed explanation goes here
    
properties
end

methods  (Static)  

    %% vjFormatToMatlabMain
    
    function vjFormatToMatlabMain()
        
        configManager = ConfigManager.get();
        config = configManager.read();

        if config.isOnOdin
            rootDir = '/u/matanorb/experiments/';
        else
            rootDir = 'C:/technion/theses/Experiments/';            
        end
        
        inputDirectory = [rootDir 'VJ/'];
        fileIdentifier{1} = 'v4.w1';
        fileIdentifier{2} = 'v4.w7';
        fileIdentifier{3} = 'v8.w1';
        fileIdentifier{4} = 'v8.w7';
        num_files = length(fileIdentifier);
        for file_i = 1:num_files
            VJGenerator.vjFormatToMatlab( inputDirectory, fileIdentifier{file_i} )
        end
    end
    
    %% vjFormatToMatlab
    
    function vjFormatToMatlab( inputDirectory, fileIdentifier )
        TRAIN = 1; DEV = 2; TEST = 3;
        inputFilesFullPath{TRAIN} = [inputDirectory 'train.' fileIdentifier '.libsvm.dat.matlab1'];
        inputFilesFullPath{DEV}   = [inputDirectory 'dev.'   fileIdentifier '.libsvm.dat.matlab1'];
        inputFilesFullPath{TEST}  = [inputDirectory 'test.'  fileIdentifier '.libsvm.dat.matlab1'];
        num_files = length(inputFilesFullPath);
        for file_i = 1:num_files
            Logger.log(['sparseKnn::vjFormatToMatlab. loading = ''' inputFilesFullPath{file_i} '''']);
            data = load(inputFilesFullPath{file_i}); 
            labels = data(:,1);
            features = data(:,2:2:end);
            num_instances = length(labels);
            Logger.log(['sparseKnn::vjFormatToMatlab. num_instances = ' num2str(num_instances)]);
            num_features = size(features, 2);
            Logger.log(['sparseKnn::vjFormatToMatlab. num_features = '  num2str(num_features)]);
            assert(num_features == size(features, 2));
            allFeatures{file_i}.instances = features; %#ok<AGROW>
            allFeatures{file_i}.labels    = labels; %#ok<AGROW>
            [~, name, ~] = fileparts(inputFilesFullPath{file_i});
            allFeatures{file_i}.name      = name; %#ok<AGROW>
        end
        
        outputFileFullPath = [ inputDirectory 'trainAndDev.instances.' fileIdentifier '.mat'];
        graph.instances = [allFeatures{TRAIN}.instances; allFeatures{DEV}.instances];
        graph.labels    = [allFeatures{TRAIN}.labels;    allFeatures{DEV}.labels];
        graph.name      = ['trainAndDev' allFeatures{TRAIN}.name]; %#ok<STRNU>
        Logger.log(['sparseKnn::vjFormatToMatlab. (trainAndDev) num_instances = ' num2str(length(graph.labels))]);
        Logger.log(['sparseKnn::vjFormatToMatlab. output file = ''' outputFileFullPath '''']);
        save(outputFileFullPath, 'graph');
        clear graph;
        
        outputFileFullPath = [ inputDirectory 'trainAndTest.instances.' fileIdentifier '.mat'];
        graph.instances = [allFeatures{TRAIN}.instances; allFeatures{TEST}.instances];
        graph.labels    = [allFeatures{TRAIN}.labels;    allFeatures{TEST}.labels];
        graph.name      = ['trainAndTest' allFeatures{TRAIN}.name]; %#ok<STRNU>
        Logger.log(['sparseKnn::vjFormatToMatlab. (trainAndTest) num_instances = ' num2str(length(graph.labels))]);
        Logger.log(['sparseKnn::vjFormatToMatlab. output file = ''' outputFileFullPath '''']);
        save(outputFileFullPath, 'graph');
        clear graph;
    end
end % methods (Static)
    
end

