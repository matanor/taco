function asyncSingleRun(fileFullPath, codeRoot)
    Configurations.setupAsyncRun('asyncSingleRun', fileFullPath, codeRoot)

    runData = load(fileFullPath);
    singleRunFactory    = runData.this;
	algorithmParams     = runData.algorithmParams;
    algorithmsToRun     = runData.algorithmsToRun;
    graphFileFullPath   = runData.graphFileFullPath;

    graph = ExperimentGraph;
    graph.load( graphFileFullPath )
    graph.removeExtraSplitVertices...
        ( singleRunFactory.m_constructionParams.numFolds);
    singleRunFactory.set_graph(graph);
    
    singleRun = singleRunFactory.run( algorithmParams, algorithmsToRun, fileFullPath );
    
    JobManager.saveJobOutput( singleRun, fileFullPath);
    JobManager.signalJobIsFinished( fileFullPath );
end
