classdef LocalScaling
    
methods (Static)

%% main

function main(filePrefix)
    instancesFilePath = [filePrefix '.mat'];
    Logger.log(['Loading instances from ''' instancesFilePath '''']);
    fileData = load(instancesFilePath,'graph');
    Logger.log('Done');
    instancesFile = fileData.graph;
    clear fileData;
    
    % get correct label information
    
    if isfield(instancesFile, 'phoneids39')
        labels = instancesFile.phoneids39;
    else
        labels = instancesFile.labels;
    end
    
    % get structured information from instances file, if available
    
    if isfield(instancesFile, 'structuredEdges')
        structuredEdges     = instancesFile.structuredEdges;
    end
    if isfield(instancesFile, 'segments')
        segments            = instancesFile.segments;
    end
    if isfield(instancesFile, 'transitionMatrix39')
        transitionMatrix    = instancesFile.transitionMatrix39;
    end
    clear instancesFile;
    
    % load K-NN graph
    
    knnGraphPath = [filePrefix '.k_10.mat'];
    Logger.log(['Loading K-NN graph from ''' knnGraphPath '''']);
    fileData = load(knnGraphPath,'graph');
    Logger.log('Done');
    graph = fileData.graph;
    clear fileData;
    
    % transform weights to distances
    
    Logger.log('Creating weights from distances...(lihi)');
    K = 10;
    graph = LocalScaling.scaleGraph(graph, K);
    graph.name = [graph.name '_lihi'];
    graph.labels = labels;
    
    % set structured information on output graph, if any
    
    if exist('structuredEdges') %#ok<EXIST>
        graph.structuredEdges   = structuredEdges;
    end
    if exist('segments') %#ok<EXIST>
        graph.segments          = segments;
    end
    if exist('transitionMatrix') %#ok<EXIST>
        graph.transitionMatrix  = transitionMatrix;
    end
    
    % write output
    
    outputFilePath = [filePrefix '.k_10.local.mat'];
    Logger.log(['Saving scaled output graph to ''' outputFilePath '''']);
    save(outputFilePath,'graph','-v7.3');
    Logger.log('Done');
end

%% scaleGraph
%  This works well on dektop (~3 minutes) but is very alow on odin
%  (over a day and didn't finish). Might be because of differences
%  in matlab version.
%  input:
%  graph - should contain a graph.distances field, containing a matrix
%          of squared distances.
%          matrix has to contain per each row its nearest neighbours.
%          it does not have to be symmetric.
%  K     - The distance to the K-th nearest neighbour is considered as
%          the local sigma.
%  output:
%  graph - adds a field graph.weights with the edge weights.

function graph = scaleGraph(graph, K)
    squared_distances = Symmetry.makeSymetric(graph.distances);
    numInstances = size(squared_distances,1);

    sigma = zeros(numInstances, 1);
    Logger.log('Calculating local sigma...');
    for instance_i=1:numInstances
        [~,~,squared_distance_i] = find(squared_distances(:,instance_i));
        [~, sortOrder] = sort(squared_distance_i, 1, 'ascend' ); % ascending order
        sigma(instance_i) = sqrt(squared_distance_i(sortOrder(K)));
        if sigma(instance_i) == 0
            sigma(instance_i) = max(squared_distance_i);
            Logger.log(['LocalScaling::scaleGraph.' ...
                        ' Warning, distance to K-th (' num2str(K) ') NN is 0.'   ...
                        ' instance_i = ' num2str(instance_i) ...
                        ' set sigma to ' num2str(sigma(instance_i))]);
        end
    end
    
    allRows = [];
    allCols = [];
    allValues = [];
    Logger.log(['Number of non zeros distances = ' num2str(nnz(squared_distances))]);
    Logger.log('Calculating weights...');
    for instance_i=1:numInstances
        if mod(instance_i, 10000) == 0
            Logger.log(['LocalScaling::scaleGraph. ' ...
                        'instance_i = ' num2str(instance_i)]);
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
    
end % static methods
    
end



