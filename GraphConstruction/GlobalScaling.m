classdef GlobalScaling
    
methods (Static)

%% main

function main(filePrefix)
    instancesFilePath = [filePrefix '.mat'];
    Logger.log(['Loading instances from ''' instancesFilePath '''']);
    fileData = load(instancesFilePath,'graph');
    Logger.log('Done');
    instancesFile = fileData.graph;
    clear fileData;
    precentToSample = 0.025;
    rbfScale            = GlobalScaling.calculateRbfScaleFromGraph...
                                        (instancesFile, precentToSample);
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
    graph = GlobalScaling.scaleGraph(graph, rbfScale);
    
    Logger.log('Symetrizing weights...');
    graph.weights = Symetry.makeSymetric(graph.weights);
    
    graph.name = [graph.name '_global'];
    graph.labels = labels;
    graph.structuredEdges = structuredEdges;
    graph.segments = segments;
    graph.transitionMatrix = transitionMatrix;
    
    outputFilePath = [filePrefix '.k_10.alex.mat'];
    Logger.log(['Saving scaled output graph to ''' outputFilePath '''']);
    save(outputFilePath,'graph','-v7.3');
    Logger.log('Done');
end

%% scaleGraph

function graph = scaleGraph(graph, rbfScale)
    squared_distances = graph.distances;
    [numRows numCols] = size(squared_distances);
    [rows,cols,values] = find(squared_distances);
    values = exp( - values / rbfScale );
    graph.weights = sparse(rows,cols,values, numRows, numCols);
end
    
%% calculateRbfScaleFromGraph
%  input: 
%  graph.instances: a matrix of size (num_features X num_instances).
%  graph.labeles:   correct labels. a vector of size (num_instances X 1).
%  output:          RBF scale.
%                   This is the parameter \alpha for
%                   a gaussian kernel
%                   exp( - ||x_i - x_j||_2^2 / \alpha )

function R = calculateRbfScaleFromGraph( graph, precentToSample )
    allInstances        = graph.instances;
    allCorrectLabels    = graph.labels;
    numInstances        = length(allCorrectLabels);
    sampledInstances    = randi(numInstances, 1, floor(precentToSample * numInstances));
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
    
end % static methods
    
end



