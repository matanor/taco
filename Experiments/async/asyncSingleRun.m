function asyncSingleRun(fileFullPath, codeRoot)
    Configurations.setupAsyncRun('asyncSingleRun', fileFullPath, codeRoot)

    runData = load(fileFullPath);
    singleRunFactory    = runData.this;
	algorithmParams     = runData.algorithmParams;
    algorithmsToRun     = runData.algorithmsToRun;

    graph = ExperimentGraph;
    graph.load      ( singleRunFactory.m_constructionParams.fileName )
    singleRunFactory.set_graph(graph);
    disp(['size(graph.w_nn)_ = '          num2str(size(graph.w_nn))]);
    disp(['size(graph.w_nn_symetric)_ = ' num2str(size(graph.w_nn_symetric))]);
    
    singleRun = singleRunFactory.run( algorithmParams, algorithmsToRun );
    
    JobManager.saveJobOutput( singleRun, fileFullPath);
    JobManager.signalJobIsFinished( fileFullPath );
end
