function asyncSingleRun(fileName, codeRoot)
%RUNONODIN Summary of this function goes here
%   Detailed explanation goes here
    disp('asyncSingleRun');
    Configurations.clearEverything();

    disp(['sharedGraphFileName = ' sharedGraphFileName]);
    disp(['fileName = ' fileName]);
    disp(['codeRoot = ' codeRoot]);
    
    codeFolders = genpath(codeRoot);
    addpath(codeFolders);

    runData = load(fileName);
    singleRunFactory = runData.this;
    graph = GraphLoader.constructGraph( singleRunFactory.m_constructionParams );
    singleRunFactory.m_graph.w_nn           = graph.w_nn;
    singleRunFactory.m_graph.w_nn_symetric  = graph.w_nn_symetric;
    
    singleRun = singleRunFactory.run( runData.algorithmParams, runData.algorithmsToRun );
    
    outputFileName      = [fileName '.out'];
    finishedFileName    = [fileName '.finished'];
    dummy = 1;
    save(outputFileName, 'singleRun');
    save(finishedFileName, 'dummy')
end
