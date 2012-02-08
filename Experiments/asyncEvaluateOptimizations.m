function asyncEvaluateOptimizations(fileFullPath, codeRoot)
    Configurations.setupAsyncRun('asyncEvaluateOptimizations', fileFullPath, codeRoot)    

    runData = load(fileFullPath);
    optimizationJobNames = runData.optimizationJobNames;
    algorithmType        = runData.algorithmType;
    optimizeBy           = runData.optimizeBy;
    
    optimal = ExperimentRunFactory.evaluateAndFindOptimalParams...
        (optimizationJobNames, algorithmType, optimizeBy);
    
    JobManager.saveJobOutput( optimal, fileFullPath);
    JobManager.signalJobIsFinished( fileFullPath );
end
