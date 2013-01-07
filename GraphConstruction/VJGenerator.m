classdef VJGenerator
    %VJGenerator Summary of this class goes here
    %   Detailed explanation goes here
    
properties (Constant)
    V4_W1 = 1;
    V4_W7 = 2;
    V8_W1 = 3;
    V8_W7 = 4;
end

methods  (Static)  

    %% generateTrunsductionSets_main
    
    function generateTrunsductionSets_main()
        allFileIdentifiers{1} = 'v4.w1';
        allFileIdentifiers{2} = 'v4.w7';
        allFileIdentifiers{3} = 'v8.w1';
        allFileIdentifiers{4} = 'v8.w7';
        num_files = length(allFileIdentifiers);
        for file_i = 1:num_files
            fileIdentifier = allFileIdentifiers{file_i};
            VJGenerator.generateTrunsductionSets(fileIdentifier);
        end
    end
    
    %% generateTrunsductionSets
    
    function generateTrunsductionSets(fileIdentifier)
        rootDirectory = ['c:/technion/theses/experiments/VJ/' fileIdentifier '/'];
        
        fileExtension = '.mat';
        trainFullPath = [rootDirectory 'train.' fileIdentifier fileExtension];
        devFullPath   = [rootDirectory 'dev.'   fileIdentifier fileExtension];
        testFullPath  = [rootDirectory 'test.'  fileIdentifier fileExtension];
        train = load(trainFullPath);
        dev   = load(devFullPath);
        test  = load(testFullPath);
        numTrain = length(train.labels);
        labelsTrain = train.labels;
        numDev   = length(dev.labels);
        numTest  = length(test.labels);
        
        precentLabeledToSample = [0.01 0.1];
        for precent_labeled_i=precentLabeledToSample
            numLabeled = floor(precent_labeled_i * numTrain / 100);
            trunsductionSets  = VJGenerator.createExperimentTransductionSets...
                                (numTrain, numDev, numTest, numLabeled, labelsTrain); %#ok<NASGU>
            trunsductionSetsOutputFullPath = ...
                 [rootDirectory fileIdentifier '.TrunsSet_' num2str(precent_labeled_i) '.mat'];
            Logger.log(['Saving to file ''' trunsductionSetsOutputFullPath '''']);
            save(trunsductionSetsOutputFullPath,'trunsductionSets');
        end
    end
    
    %% createExperimentTransductionSets
    
    function R = createExperimentTransductionSets...
                (numTrain, numDev, numTest, numLabeled, labelsTrain)
        t = ExperimentTrunsductionSets();
        Logger.log(['VJGenerator::createExperimentTransductionSets.' ...
                    ' numTrain = '      num2str(numTrain) ...
                    ' numDev = '        num2str(numDev) ...
                    ' numTest = '       num2str(numTest) ...
                    ' numLabeled = '    num2str(numLabeled) ...
                    ]);
        t.m_optimizationSets = VJGenerator.createTransductionSet(numTrain, numDev,  numLabeled, labelsTrain);
        t.m_evaluationSets   = VJGenerator.createTransductionSet(numTrain, numTest, numLabeled, labelsTrain);
        
        R = t;
    end
    
        %% createTransductionSet
    
    function R = createTransductionSet(numTrain, numTest, numLabeled, labelsTrain)
        t = TrunsductionSet(1);
        % all are column vectors
        t.m_training        = (1:numTrain).';
        t.m_testing         = numTrain + ((1:numTest).');
        randomPermutation   = randperm(numTrain);
        sampled             = (randomPermutation(1:numLabeled)).';
        labeledSampled = labelsTrain(sampled);
        Logger.log(['unique(labeledSampled) = ' num2str(unique(labeledSampled).')]);
        t.m_labeled         = sampled;
        
        R = t;
    end
    
    %% scale_all_VJ_graphs
    
    function scale_all_VJ_graphs()
        rootDirectoty = 'c:/technion/theses/experiments/VJ/';
        allFilePrefixes{1} = [rootDirectoty 'trainAndDev/trainAndDev.instances.v4.w1'];
        allFilePrefixes{2} = [rootDirectoty 'trainAndDev/trainAndDev.instances.v4.w7'];
        allFilePrefixes{3} = [rootDirectoty 'trainAndDev/trainAndDev.instances.v8.w1'];
        allFilePrefixes{4} = [rootDirectoty 'trainAndTest/trainAndTest.instances.v4.w1'];
        allFilePrefixes{5} = [rootDirectoty 'trainAndTest/trainAndTest.instances.v4.w7'];
        allFilePrefixes{6} = [rootDirectoty 'trainAndTest/trainAndTest.instances.v8.w1'];
%         allFilePrefixes{7} = [rootDirectoty 'trainAndDev/trainAndDev.instances.v8.w7'];
%         allFilePrefixes{8} = [rootDirectoty 'trainAndTest/trainAndTest.instances.v8.w7'];
        num_files = length(allFilePrefixes);
        for file_i = 1:num_files
            filePrefix = allFilePrefixes{file_i};
            LocalScaling.main(filePrefix);
        end
    end
    
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
        allInputFilesFullPath{TRAIN} = [inputDirectory 'train.' fileIdentifier '.libsvm.dat.matlab1'];
        allInputFilesFullPath{DEV}   = [inputDirectory 'dev.'   fileIdentifier '.libsvm.dat.matlab1'];
        allInputFilesFullPath{TEST}  = [inputDirectory 'test.'  fileIdentifier '.libsvm.dat.matlab1'];
        num_files = length(allInputFilesFullPath);
        for file_i = 1:num_files
            inputFileFullPath = allInputFilesFullPath{file_i};
            Logger.log(['VJGenerator::vjFormatToMatlab. loading = ''' inputFileFullPath '''']);
            data = load(inputFileFullPath); 
            labels = data(:,1);
            features = data(:,3:2:end);
            num_instances = length(labels);
            Logger.log(['VJGenerator::vjFormatToMatlab. num_instances = ' num2str(num_instances)]);
            num_features = size(features, 2);
            Logger.log(['VJGenerator::vjFormatToMatlab. num_features = '  num2str(num_features)]);
            assert(num_features == size(features, 2));
            allFeatures{file_i}.instances = features; %#ok<AGROW>
            allFeatures{file_i}.labels    = labels; %#ok<AGROW>
            [path, name, ~] = fileparts(inputFileFullPath);
            % name is like 'dev.v4.w1.libsvm.dat.matlab1'
            dots = strfind(name, '.');
            name = name(1:(dots(3)-1));
            outputFeaturesFullPath = [path '/' name '.mat'];
            Logger.log(['VJGenerator::vjFormatToMatlab. outputFeaturesFullPath = ''' outputFeaturesFullPath  '''']);
            save(outputFeaturesFullPath, 'features', 'labels')
        end
        
        outputFileFullPath = [ inputDirectory 'trainAndDev/trainAndDev.instances.' fileIdentifier '.mat'];
        graph.instances = [allFeatures{TRAIN}.instances; allFeatures{DEV}.instances].';
        graph.labels    = [allFeatures{TRAIN}.labels;    allFeatures{DEV}.labels];
        graph.name      = ['trainAndDev.' fileIdentifier]; %#ok<STRNU>
        Logger.log(['VJGenerator::vjFormatToMatlab. (trainAndDev) num_instances = ' num2str(length(graph.labels))]);
        Logger.log(['VJGenerator::vjFormatToMatlab. output file = ''' outputFileFullPath '''']);
        save(outputFileFullPath, 'graph');
        clear graph;
        
        outputFileFullPath = [ inputDirectory 'trainAndTest/trainAndTest.instances.' fileIdentifier '.mat'];
        graph.instances = [allFeatures{TRAIN}.instances; allFeatures{TEST}.instances].';
        graph.labels    = [allFeatures{TRAIN}.labels;    allFeatures{TEST}.labels];
        graph.name      = ['trainAndTest.' fileIdentifier]; %#ok<STRNU>
        Logger.log(['VJGenerator::vjFormatToMatlab. (trainAndTest) num_instances = ' num2str(length(graph.labels))]);
        Logger.log(['VJGenerator::vjFormatToMatlab. output file = ''' outputFileFullPath '''']);
        save(outputFileFullPath, 'graph');
        clear graph;
    end
end % methods (Static)
    
end

