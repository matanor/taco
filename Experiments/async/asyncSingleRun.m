function asyncSingleRun(fileFullPath, codeRoot)
    Configurations.setupAsyncRun('asyncSingleRun', fileFullPath, codeRoot)

    runData = load(fileFullPath);
    singleRunFactory    = runData.this;
	algorithmParams     = runData.algorithmParams;
    algorithmsToRun     = runData.algorithmsToRun;

    graph = ExperimentGraph;
    graph.load( singleRunFactory.m_constructionParams.fileName )
    graph.removeExtraSplitVertices...
        ( singleRunFactory.m_constructionParams.numFolds);
    singleRunFactory.set_graph(graph);
    
    singleRun = singleRunFactory.run( algorithmParams, algorithmsToRun, fileFullPath );
    
    JobManager.saveJobOutput( singleRun, fileFullPath);
    JobManager.signalJobIsFinished( fileFullPath );
end
