function asyncEvaluateOptimizations(fileFullPath, codeRoot)
    Configurations.setupAsyncRun('asyncEvaluateOptimizations', fileFullPath, codeRoot)    

    runData = load(fileFullPath);
    optimizationJobNames = runData.optimizationJobNames;
    
    optimal = ExperimentRunFactory.evaluateAndFindOptimalParams(optimizationJobNames);
    
    JobManager.saveJobOutput( optimal, fileFullPath);
    JobManager.signalJobIsFinished( fileFullPath );
end
