function asyncSingleRun(fileFullPath, codeRoot)
    Configurations.setupAsyncRun('asyncSingleRun', fileFullPath, codeRoot)

    runData = load(fileFullPath);
    singleRunFactory    = runData.this;
	algorithmParams     = runData.algorithmParams;
    algorithmsToRun     = runData.algorithmsToRun;

    graph = ExperimentGraph;
    graph.load      ( singleRunFactory.m_constructionParams.fileName )
    singleRunFactory.set_graph(graph);
    
    singleRun = singleRunFactory.run( algorithmParams, algorithmsToRun );
    
    JobManager.saveJobOutput( singleRun, fileFullPath);
    JobManager.signalJobIsFinished( fileFullPath );
end
