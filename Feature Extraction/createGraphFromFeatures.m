
function createGraphFromFeatures(fileName, labelsFileName, outputFileName, graphName)
    %% load the feature vectors
    inputData = load(fileName);
    tfidf = inputData.tfidf;

    %% calculate the graph weights
    weights = tfidf * tfidf .';

    %% make the weights non-sparse
    weights = full(weights);

    %% zero the main diagonal - no one vertice loops
    weights = zeroMainDiagonal( weights );

    imshow(weights,[]);
    %% put the weights in the graph
    graph.weights = weights;

    %% read the labels file
    labels = csvread(labelsFileName);

    %% put labels in the graph
    graph.labels = labels;
    graph.name = graphName; %#ok<STRNU>

    save(outputFileName, 'graph' );
end