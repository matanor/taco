function asyncEvaluateOptimizations(fileFullPath, codeRoot)
    Configurations.setupAsyncRun('asyncEvaluateOptimizations', fileFullPath, codeRoot)    

    runData = load(fileFullPath);
    optimizationJobNames = runData.optimizationJobNames;
    algorithmType        = runData.algorithmType;
    optimizeBy           = runData.optimizeBy;
    
    Logger.log(['optimizeBy = ' num2str(optimizeBy)]);
    Logger.log(['algorithmType = ' num2str(algorithmType)]);
    algorithmName = AlgorithmTypeToStringConverter.convert(algorithmType);
    Logger.log(['algorithmName = ' num2str(algorithmName)]);
    
    optimal = ExperimentRunFactory.evaluateAndFindOptimalParams...
        (optimizationJobNames, algorithmType, optimizeBy);
    
    JobManager.saveJobOutput( optimal, fileFullPath);
    JobManager.signalJobIsFinished( fileFullPath );
end
