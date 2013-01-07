classdef TIMIT

methods  (Static)  
    
%% main

function main()
    fileNameTrain   = 'timitTrainMFCC' ;
    fileNameDev     = 'timitDevMFCC';
    fileNameTest    = 'timitTestMFCC';
    
	isUseCmsWhiteFeatures = 1;
    context = 7;
    maxFeaturesToExtract = 39;
    
    trainAndDevGraphName  = 'trainAndDev';
    trainAndTestGraphName = 'trainAndTest';
    
    TIMIT.combineInstanceFilesWrapper...
        (fileNameTrain, fileNameDev, trainAndDevGraphName, ...
         isUseCmsWhiteFeatures, context, maxFeaturesToExtract);
     
    TIMIT.combineInstanceFilesWrapper...
        (fileNameTrain, fileNameTest, trainAndTestGraphName, ...
         isUseCmsWhiteFeatures, context, maxFeaturesToExtract);
end

%% combineInstanceFilesWrapper

function combineInstanceFilesWrapper( fileName1, fileName2, graphName, ...
                                      isUseCmsWhiteFeatures, context, ...
                                      maxFeaturesToExtract)
    Logger.log('combineInstanceFilesWrapper')
    folderPath = TIMIT.graphFolder();
    
    if isUseCmsWhiteFeatures
        graphNameSuffix     = '_cms_white';
        folderSuffix        = '_cms_white';
        inputFileSuffix     = '_cms_white';
    else
        graphNameSuffix     = '_notWhite';
        folderSuffix        = [];
        inputFileSuffix     = [];
    end
    
    filePaths{1} = [folderPath fileName1 inputFileSuffix '.mat'];
    filePaths{2} = [folderPath fileName2 inputFileSuffix '.mat'];

    graphName = [graphName graphNameSuffix];
    
    folderPath = [folderPath 'features_' num2str(maxFeaturesToExtract) folderSuffix '/'];
    mkdir(folderPath);
    outputPath = [folderPath graphName];

    TIMIT.combineInstanceFiles(filePaths, graphName, outputPath, ...
                                             context,   maxFeaturesToExtract );
end

%% combineInstanceFiles
%  Used for generating the train+dev or train+test instance files.

function combineInstanceFiles(filePaths, graphName, outputPath, context, ...
                              maxFeaturesToExtract)
    numFiles = length(filePaths);
    instances = [];
    phoneids48 = [];
    phoneids39 = [];
    segments = [];
    for file_i=1:numFiles
        isTrainFile = 0;
        currentFilePath = filePaths{file_i};
        fileData = load(currentFilePath);
        if isfield(fileData, 'trainData')
            Logger.log('TIMIT::combineInstanceFiles. Found train data');
            fileData = fileData.trainData;
            isTrainFile = 1;
        elseif isfield(fileData, 'testData')
            Logger.log('TIMIT::combineInstanceFiles. Found test data');
            fileData = fileData.testData;
        elseif isfield(fileData, 'devData')
            Logger.log('TIMIT::combineInstanceFiles. Found dev data');
            fileData = fileData.devData;
        else
            Logger.log('combineInstanceFiles. Error, unknown file format');
        end
        
        numVerticesInFile = size(fileData.phonemfcc, 2);
        Logger.log(['TIMIT::combineInstanceFiles. num vertices in file = ' num2str(numVerticesInFile)]);
        
        numVerticesSoFar = size(instances,2);
        
        if isTrainFile
            Logger.log(['Calculating train covariance from file' currentFilePath]);
            trainRange = (numVerticesSoFar+1):numVerticesInFile;
            Logger.log(['trainRange = ' num2str(trainRange(1)) ' ' num2str(trainRange(end))]);
        end
        
        instances  = [instances   fileData.phonemfcc(1:maxFeaturesToExtract,:)]; %#ok<AGROW>
        phoneids48 = [phoneids48; fileData.phoneids48.']; %#ok<AGROW>
        phoneids39 = [phoneids39; fileData.phoneids39.']; %#ok<AGROW>
        segments   = [segments;   fileData.seg + numVerticesSoFar]; %#ok<AGROW>
    end
    
    graph.instances  = instances;
    graph.name       = graphName;
    graph.labels     = phoneids39;
    graph.structuredEdges    = Structured.segmentsToStructuredEdges(segments);
    graph.phoneids48 = phoneids48;
    graph.phoneids39 = phoneids39;
    graph.transitionMatrix48 = Structured.estimateTransitionMatrix(phoneids48, segments);
    graph.segments   = segments;
    graph.transitionMatrix39 = Structured.estimateTransitionMatrix(phoneids39, segments); %#ok<STRNU>
    Logger.log(['Saving instances to ''' outputPath ''''])
    save([outputPath '.mat'], 'graph');
    
    if context ~=0
        graph.instances = ...
            Structured.createInstancesWithContext...
                (graph.instances, context, segments);
        Logger.log('Calculating covariance for all instances' );
        graph.covariance = cov(graph.instances.');
        Logger.log('Calculating covariance for train instances' );
        trainCovariance  = cov(graph.instances(:,trainRange).');
        graph.trainCovariance = trainCovariance;
        outputFileFullPath = [outputPath '.context' num2str(context)];
        Logger.log(['Saving instances with context to '''  outputFileFullPath '''' ])
        save([outputFileFullPath '.mat'], 'graph','-v7.3');
        
        Logger.log('Whitening instances ...');
        white_transform  = sqrtm(inv(trainCovariance));
        graph.instances  = white_transform * graph.instances;
        Logger.log('Calculating covariance for all instances');
        graph.covariance      = cov(graph.instances.');
        Logger.log('Calculating covariance for train instances');
        graph.trainCovariance = cov(graph.instances(:,trainRange).');
        outputFileFullPath = [outputFileFullPath '_whitened'];
        Logger.log(['Saving whitened instances with context to '''  outputFileFullPath '''' ])
        save([outputFileFullPath '.mat'], 'graph','-v7.3');
    end
    
end


%% graphFolder

function R = graphFolder()
    configManager   = ConfigManager.get();
    config          = configManager.read();
    if config.isOnOdin
        R = '/u/matanorb/experiments/timit/';
    else
        R = 'C:/technion/theses/experiments/timit/';
    end
end

end % methods (Static)
    
end

