function asyncSingleRun(fileFullPath, codeRoot)
%RUNONODIN Summary of this function goes here
%   Detailed explanation goes here
    disp('asyncSingleRun');
    Configurations.clearEverything();

    disp(['fileFullPath = ' fileFullPath]);
    disp(['codeRoot = ' codeRoot]);
    
    codeFolders = genpath(codeRoot);
    addpath(codeFolders);

    runData = load(fileFullPath);
    singleRunFactory = runData.this;
    graph = GraphLoader.constructGraph( singleRunFactory.m_constructionParams );
    singleRunFactory.m_graph.weights        = graph.weights;
    singleRunFactory.m_graph.w_nn           = graph.w_nn;
    singleRunFactory.m_graph.w_nn_symetric  = graph.w_nn_symetric;
    disp(['size(graph.w_nn)_ = '          num2str(size(graph.w_nn))]);
    disp(['size(graph.w_nn_symetric)_ = ' num2str(size(graph.w_nn_symetric))]);
    
    singleRun = singleRunFactory.run( runData.algorithmParams, runData.algorithmsToRun );
    
    JobManager.saveJobOutput( singleRun, fileFullPath);
    JobManager.signalJobIsFinished( fileFullPath );
end
