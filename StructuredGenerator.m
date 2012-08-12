classdef StructuredGenerator
    %STRUCTUREDGENERATOR Summary of this class goes here
    %   Detailed explanation goes here
    
properties
    m_gaussianMean;  % Each column is a mean vector for an output gaussian distribution
    m_gaussianCovariance; % Each column is the main diagonal for an output gaussian distribution
    m_transitions;
    m_prior;
end

methods
    
    %% createSequence
    
    function [output, states] = createSequence(this)
        minSequenceLength = 1000;
        sequenceLength = minSequenceLength + randi(1000,1);

        numFeatures = size(this.m_gaussianMean, 2);
        initialState = randp( this.m_prior, 1);
        currentState = initialState;
        states = zeros(sequenceLength, 1);
        output = zeros(sequenceLength, numFeatures);
        for sequence_i=1:sequenceLength
            outputMean        = this.m_gaussianMean      ( currentState, : );
            outptutCovariance = this.m_gaussianCovariance( :, :, currentState );
            currentOutput = mvnrnd(outputMean,outptutCovariance,1);
            states(sequence_i) = currentState;
            output(sequence_i,:) = currentOutput;
            probabilitiesToNextState = this.m_transitions(:, currentState).';
            assert(sum(probabilitiesToNextState) == 1);
            nextState = randp(probabilitiesToNextState, 1);
            currentState = nextState;
        end
    end
    
    %% saveGraph

    function saveGraph(this, graph)
        outputFolder = 'C:\technion\theses\Experiments\StructureSynthetic\data';
        graphName = [outputFolder '\' graph.name];
        graph.transitionMatrix = this.m_transitions;
        numVertices = length(graph.labels);
        graph.structuredEdges = [(1:(numVertices-1)).' (2:(numVertices)).'];
        save(graphName, 'graph');        
    end
    
end % methods

methods (Static)
    
function main()
    s = StructuredGenerator;
    s.m_gaussianMean = [0 0;
                        0 0];
    s.m_gaussianCovariance(:,:,1) = [3 1.5;
                                     1.5 1];
    s.m_gaussianCovariance(:,:,2) = [3 -1.5;
                                     -1.5 1];
    s.m_transitions = [ 0.9 0.1 ;
                        0.1 0.9 ];
    s.m_prior = [0.5 0.5];
    %dbstop in StructuredGenerator.m at 53;
    [output states] = s.createSequence();

    class1 = output(states == 1, :);
    class2 = output(states == 2, :);
    hold on;
    scatter(class1(:,1), class1(:,2) );
    scatter(class2(:,1), class2(:,2) );
    hold off;

    context = 1;
    graph = s.createGraph(states, output, context);
%         s.saveGraph( graph );

    context = 7;
    graph = s.createGraph(states, output, context);
%         s.saveGraph( graph );
end

%% createInstancesWithContext
%  instances is numfeatures X numinstances.
%  from it create instances with structure:
%  instance_with_context(i) = [ ... instance(i-1) instance(i) instance(i+1) ...]
%  Use segments to avoid generating sontext across different segments.
%  context - the amount of context to generate around a single instance.
%  should be odd, e.g. 7 will take -+3 from the middle instance

function R = createInstancesWithContext(instances, context, segments)
    numInstances    = size(instances, 2);
    numFeatures     = size(instances, 1);
    dummyContext = zeros(1, numFeatures); % some dummy value
    instances_with_context = zeros(context * numFeatures, numInstances);
    numSegments = size(segments, 1);
    
    Logger.log(['StructuredGenerator::createInstancesWithContext. numInstances = ' num2str(numInstances)]);
    Logger.log(['StructuredGenerator::createInstancesWithContext. numFeatures = '  num2str(numFeatures)]);
    Logger.log(['StructuredGenerator::createInstancesWithContext. numSegments = '  num2str(numSegments)]);
    
    instanceCount = 1;
    for segment_i=1:numSegments
        segmentStart = segments(segment_i,1);
        segmentEnd   = segments(segment_i,2);
        segmentFramesRange = segmentStart:segmentEnd;
        for instance_i=segmentFramesRange
            if mod(instanceCount,100000) == 0
                Logger.log(['StructuredGenerator::createInstancesWithContext. instanceCount = ' num2str(instanceCount)]);
            end
            half_context = (context - 1)/2;
            context_range = (instance_i-half_context):(instance_i+half_context);
            contextPosition = 1:numFeatures;
            for context_i=context_range
                if context_i < segmentStart || context_i > segmentEnd
                    contextInstance = dummyContext;
                else
                    contextInstance = instances(:, context_i);
                end
                instances_with_context(contextPosition, instance_i) = contextInstance;
                contextPosition = contextPosition + numFeatures;
            end
            instanceCount = instanceCount + 1;
        end
    end
    R = instances_with_context;
end

%% createGraph

function graph = createGraph( labels, instances, context )
    graph.labels = labels;
    graph.instances = instances;
    numInstances    = size(instances, 1);
    segments = [1 numInstances];
    instances_with_context = ...
        StructuredGenerator.createInstancesWithContext...
                            (instances, context, segments );
    weights = zeros(numInstances, numInstances);
    alpha = 2;
    for instance_i=1:numInstances
        x = instances_with_context(instance_i,:);
        for instance_j=1:numInstances
            y = instances_with_context(instance_j,:);
            weights(instance_i, instance_j) = exp(-sum((x-y).^2) / alpha);
        end
    end
    graph.weights = weights;
    graph.name = ['context_' num2str(context)];
end

%% segmentsToStructuredEdges

function R = segmentsToStructuredEdges(segments)
    lastSeg = segments(end,end);
    structuredEdges = [(1:lastSeg-1).' (2:lastSeg).'];
    segmentsEnd = segments(:,2);
    segmentsEnd = segmentsEnd(1:end-1); % remove last segment end
    structuredEdges(segmentsEnd,:) = [];  % remove edges from segment end to a different segment start
    R = structuredEdges;
end

%% estimateTransitionMatrix

function R = estimateTransitionMatrix(correctLabels, segments)
    Logger.log('estimateTransitionMatrix');
    numLabels = length(unique(correctLabels));
    Logger.log(['Number of classes = ' num2str(numLabels)]);
    transitions = zeros(numLabels, numLabels);
    numSegments = size(segments, 1);
    Logger.log(['Number of segments = ' num2str(numSegments)]);
    Logger.log(['Labels sequence length = ' num2str(length(correctLabels))]);
    numTransitions = 0;
    for segment_i=1:numSegments
        segmentStart = segments(segment_i,1);
        segmentEnd   = segments(segment_i,2);
        for frame_i=segmentStart:(segmentEnd-1)
            framePhone      = correctLabels(frame_i);
            nextFramePhone  = correctLabels(frame_i+1);
            transitions(nextFramePhone, framePhone) = ...
                transitions(nextFramePhone, framePhone) + 1;
            numTransitions = numTransitions +1;
        end
    end
    Logger.log(['Number of transitions = ' num2str(numTransitions)]);
    R = transitions ./ repmat(sum(transitions, 1), numLabels, 1);
end

%% sampleSegments
%  method: sample segments until at least <minNumSamplesPerLabel> frames 
%  per label are selected, label sample order is random.
%  Then, sample more segments until <precentToSample> frames are selected.

function R = sampleSegments(correctLabels, segments, precentToSample)
    numUniqueLabels = length(unique(correctLabels));
    minNumSamplesPerLabel = 1;
    numSampledFromEachLabel = zeros(numUniqueLabels, 1);
    numSegments = size(segments, 1);
    numFrames = length(correctLabels);
    Logger.log(['numLabels = ' num2str(numUniqueLabels)]);
    Logger.log(['numSegments = ' num2str(numSegments)]);
    Logger.log(['numFrames = '   num2str(numFrames)]);
    allSampledSegments = [];
    numLabeledSamples = 0;
    labelsSampleOrder = randperm(numUniqueLabels);
    Logger.log(['Sampling at least ' num2str(minNumSamplesPerLabel) ' frames per label']);
    for label_i=labelsSampleOrder
        finished = (numSampledFromEachLabel(label_i) >= minNumSamplesPerLabel);
        while ~finished
            sampledSegment = randi(numSegments, 1, 1);
            if ~ismember(sampledSegment, allSampledSegments)
                segmentStart = segments(sampledSegment, 1);
                segmentEnd   = segments(sampledSegment, 2);
                labelsInSegment = correctLabels(segmentStart:segmentEnd);
                if ismember(label_i, labelsInSegment)
                    finished = 1;
                    allSampledSegments = [allSampledSegments; sampledSegment]; %#ok<AGROW>
                    Logger.log(['Adding segment ' num2str(sampledSegment)]);
                    numLabelsInSegment = length(labelsInSegment);
                    numLabeledSamples = numLabeledSamples + numLabelsInSegment;
                    for labelInSegment_i=labelsInSegment
                        numSampledFromEachLabel(labelInSegment_i) = ...
                            numSampledFromEachLabel(labelInSegment_i) + 1;
                    end
                end
            end
        end
    end

    Logger.log('Adding additional segments');
    
    finished = numLabeledSamples > precentToSample * numFrames;

    while ~finished
        sampledSegment = randi(numSegments, 1, 1);
        if ~ismember(sampledSegment, allSampledSegments)
            segmentStart = segments(sampledSegment, 1);
            segmentEnd   = segments(sampledSegment, 2);
            labelsInSegment = correctLabels(segmentStart:segmentEnd);
            Logger.log(['Adding segment ' num2str(sampledSegment)]);
            allSampledSegments = [allSampledSegments; sampledSegment]; %#ok<AGROW>
            numLabeledSamples = numLabeledSamples + length(labelsInSegment);
        end
        finished = numLabeledSamples > precentToSample * numFrames;
    end

    assert(length(unique(allSampledSegments)) == length(allSampledSegments));

    sampledLabels = [];
    for segment_i=allSampledSegments.'
        segmentStart = segments(segment_i, 1);
        segmentEnd   = segments(segment_i, 2);
        sampledLabels = [sampledLabels; (segmentStart:segmentEnd).']; %#ok<AGROW>
    end

    Logger.log(['Sampled ' num2str(length(allSampledSegments)) ' segments' ...
                ' out of ' num2str(numSegments)]);
    Logger.log(['Sampled ' num2str(length(sampledLabels)) ' labels' ...
                ' out of ' num2str(length(correctLabels))]);
    R = sampledLabels;
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
            Logger.log('StructuredGenerator::combineInstanceFiles. Found train data');
            fileData = fileData.trainData;
            isTrainFile = 1;
        elseif isfield(fileData, 'testData')
            Logger.log('StructuredGenerator::combineInstanceFiles. Found test data');
            fileData = fileData.testData;
        elseif isfield(fileData, 'devData')
            Logger.log('StructuredGenerator::combineInstanceFiles. Found dev data');
            fileData = fileData.devData;
        else
            Logger.log('combineInstanceFiles. Error, unknown file format');
        end
        
        numVerticesInFile = size(fileData.phonemfcc, 2);
        Logger.log(['StructuredGenerator::combineInstanceFiles. num vertices in file = ' num2str(numVerticesInFile)]);
        
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
    graph.structuredEdges    = StructuredGenerator.segmentsToStructuredEdges(segments);
    graph.phoneids48 = phoneids48;
    graph.phoneids39 = phoneids39;
    graph.transitionMatrix48 = StructuredGenerator.estimateTransitionMatrix(phoneids48, segments);
    graph.segments   = segments;
    graph.transitionMatrix39 = StructuredGenerator.estimateTransitionMatrix(phoneids39, segments); %#ok<STRNU>
    Logger.log(['Saving instances to ''' outputPath ''''])
    save([outputPath '.mat'], 'graph');
    
    if context ~=0
        graph.instances = ...
            StructuredGenerator.createInstancesWithContext...
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

%% combineInstancesFilesMain

function combineInstancesFilesMain()
    fileNameTrain   = 'timitTrainMFCC' ;
    fileNameDev     = 'timitDevMFCC';
    fileNameTest    = 'timitTestMFCC';
    
	isUseCmsWhiteFeatures = 1;
    context = 7;
    maxFeaturesToExtract = 39;
    
    trainAndDevGraphName  = 'trainAndDev';
    trainAndTestGraphName = 'trainAndTest';
    
    StructuredGenerator.combineInstanceFilesWrapper...
        (fileNameTrain, fileNameDev, trainAndDevGraphName, ...
         isUseCmsWhiteFeatures, context, maxFeaturesToExtract);
     
    StructuredGenerator.combineInstanceFilesWrapper...
        (fileNameTrain, fileNameTest, trainAndTestGraphName, ...
         isUseCmsWhiteFeatures, context, maxFeaturesToExtract);
end

%% combineInstanceFilesWrapper

function combineInstanceFilesWrapper( fileName1, fileName2, graphName, ...
                                      isUseCmsWhiteFeatures, context, ...
                                      maxFeaturesToExtract)
    Logger.log('combineInstanceFilesWrapper')
    folderPath = StructuredGenerator.timitGraphsFolder();
    
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

    StructuredGenerator.combineInstanceFiles(filePaths, graphName, outputPath, ...
                                             context,   maxFeaturesToExtract );
end

%% timitGraphsFolder

function R = timitGraphsFolder()
    configManager = ConfigManager.get();
    config = configManager.read();
    if config.isOnOdin
        R = '/u/matanorb/experiments/timit/';
    else
        R = 'C:/technion/theses/experiments/timit/';
    end
end
    
%     context = 7;
%     maxFeaturesToExtract = 39;

%% calculateRbfScaleFromGraph

function R = calculateRbfScaleFromGraph( graph, precentToSample )
    allInstances = graph.instances;
    allCorrectLabels = graph.labels;
    numInstances = length(allCorrectLabels);
    sampledInstances = randi(numInstances, 1, floor(precentToSample * numInstances));
    rbfScale = StructuredGenerator.calculateRbfScale(allInstances, allCorrectLabels, sampledInstances);
    R = rbfScale;
end 

%% calculateRbfScale
% reference: andrei alexandrescu Phd, section 5.7, page 103

function R = calculateRbfScale(allInstances, allCorrectLabels, sampledInstances)
    instances = allInstances(:,sampledInstances);
    clear allInstances;
    numInstances = size(instances,2);
    Logger.log(['Calling pdist for ' num2str(numInstances) ' instances']);
    D = pdist(instances.', 'euclidean'); % sqrt(sum(x_i-x_j).^2), checked with 2x2 example
    distances = squareform(D);
    Logger.log(['calculateRbfScale. distances max = '  num2str(max(distances(:)))]);
    Logger.log(['calculateRbfScale. distances min = '  num2str(min(distances(:)))]);
    Logger.log(['calculateRbfScale. distances mean = ' num2str(mean(distances(:)))]);
    
    correctLabels = allCorrectLabels(sampledInstances);
    Logger.log(['calculateRbfScale. numLabels = ' num2str(length(correctLabels))]);
    correctLabels = repmat(correctLabels, 1, numInstances);
    Logger.log('calculateRbfScale. finished repmat.');
    
    isSameLabel = (correctLabels == correctLabels.');
    clear correctLabels;
    
    d_withinClass  = sum(distances(isSameLabel));
    N_withinClass  = sum(isSameLabel(:)) - numInstances; % reduce count of main diagonal
    isDifferentLabel = ~isSameLabel;
    clear isSameLabel;
    d_betweenClass = sum(distances(isDifferentLabel));
    N_betweenClass = sum(isDifferentLabel(:));
    clear isDifferentLabel ;

    Logger.log('before normalizaiton')
    Logger.log(['calculateRbfScale. d_withinClass = ' num2str(d_withinClass)]);
    Logger.log(['calculateRbfScale. d_betweenClass = ' num2str(d_betweenClass)]);
    d_withinClass  = d_withinClass  / N_withinClass;
    d_betweenClass = d_betweenClass / N_betweenClass;
    Logger.log('after normalizaiton')
    Logger.log(['calculateRbfScale. d_withinClass = ' num2str(d_withinClass)]);
    Logger.log(['calculateRbfScale. N_withinClass = ' num2str(N_withinClass)]);
    Logger.log(['calculateRbfScale. d_betweenClass = ' num2str(d_betweenClass)]);
    Logger.log(['calculateRbfScale. N_betweenClass = ' num2str(N_betweenClass)]);
    rbfScale = (d_withinClass + d_betweenClass) / (2 * sqrt(log(2)));
    Logger.log(['calculateRbfScale. rbfScale = ' num2str(rbfScale)]);
    R = rbfScale;
end

%% createWeightsFromDistances_alex

function createWeightsFromDistances_alex(filePrefix)
    instancesFilePath = [filePrefix '.mat'];
    Logger.log(['Loading instances from ''' instancesFilePath '''']);
    fileData = load(instancesFilePath,'graph');
    Logger.log('Done');
    instancesFile = fileData.graph;
    clear fileData;
    precentToSample = 0.025;
    rbfScale = StructuredGenerator.calculateRbfScaleFromGraph(instancesFile, precentToSample);
    labels              = instancesFile.phoneids39;
    structuredEdges     = instancesFile.structuredEdges;
    segments            = instancesFile.segments;
    transitionMatrix    = instancesFile.transitionMatrix39;
    clear instancesFile;
    knnGraphPath = [filePrefix '.k_10.mat'];
    Logger.log(['Loading K-NN graph from ''' knnGraphPath '''']);
    fileData = load(knnGraphPath,'graph');
    Logger.log('Done');
    graph = fileData.graph;
    clear fileData;
    Logger.log('Creating weights from distances...');
    graph = StructuredGenerator.createWeightsFromDistances(graph, rbfScale);
    Logger.log('Symetrizing weights...');
    graph.weights = sparseKnn.makeSymetric(graph.weights);
    graph.name = [graph.name '_alex'];
    graph.labels = labels;
    graph.structuredEdges = structuredEdges;
    graph.segments = segments;
    graph.transitionMatrix = transitionMatrix;
    outputFilePath = [filePrefix '.k_10.alex.mat'];
    Logger.log(['Saving scaled output graph to ''' outputFilePath '''']);
    save(outputFilePath,'graph','-v7.3');
    Logger.log('Done');
end

%% createWeightsFromDistances

function graph = createWeightsFromDistances(graph, rbfScale)
    squared_distances = graph.distances;
    [rows,cols,values] = find(squared_distances);
    values = exp( - values / rbfScale );
    graph.weights = sparse(rows,cols,values);
end

%% createWeightsFromDistances_lihi
%  This works well on dektop (~3 minutes) but is very alow on odin
%  (over a day and didn't finish). Might be because the difference
%  in matlab version.

function graph = createWeightsFromDistances_lihi(graph, K)
    squared_distances = sparseKnn.makeSymetric(graph.distances);
    numInstances = size(squared_distances,1);

    sigma = zeros(numInstances, 1);
    Logger.log('Calculating local sigma...');
    for instance_i=1:numInstances
        [~,~,squared_distance_i] = find(squared_distances(:,instance_i));
        [~, sortOrder] = sort(squared_distance_i, 1, 'ascend' ); % ascending order
        sigma(instance_i) = sqrt(squared_distance_i(sortOrder(K)));
    end
    
    allRows = [];
    allCols = [];
    allValues = [];
    Logger.log(['Number of non zeros distances = ' num2str(nnz(squared_distances))]);
    Logger.log('Calculating weights...');
    for instance_i=1:numInstances
        if mod(numInstances, 10) == 0
            Logger.log(['createWeightsFromDistances_lihi. numInstances = ' num2str(numInstances)]);
        end
        [rows,~,values] = find(squared_distances(:,instance_i));
        sigma_for_instance = sigma(instance_i) * sigma(rows);
        allRows   = [allRows;   rows]; %#ok<AGROW>
        cols      = instance_i * ones(size(rows));
        allCols   = [allCols;   cols]; %#ok<AGROW>
        values    = exp( -values ./ sigma_for_instance );
        allValues = [allValues; values]; %#ok<AGROW>
    end
    w = sparse(allRows, allCols, allValues);
    graph.weights = w;
end

end % methods (Static)
    
end

