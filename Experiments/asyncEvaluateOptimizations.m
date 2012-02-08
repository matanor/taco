function asyncEvaluateOptimizations(fileFullPath, codeRoot)
    Configurations.setupAsyncRun('asyncEvaluateOptimizations', fileFullPath, codeRoot)    

    runData = load(fileFullPath);
    optimizationJobNames = runData.optimizationJobNames;
    algorithmType        = runData.algorithmType;
    optimizeBy           = runData.optimizeBy;
    
    disp(['optimizeBy = ' num2str(optimizeBy)]);
    disp(['algorithmType = ' num2str(algorithmType)]);
    algorithmName = AlgorithmTypeToStringConverter.convert(algorithmType);
    disp(['algorithmName = ' num2str(algorithmName)]);
    
    optimal = ExperimentRunFactory.evaluateAndFindOptimalParams...
        (optimizationJobNames, algorithmType, optimizeBy);
    
    JobManager.saveJobOutput( optimal, fileFullPath);
    JobManager.signalJobIsFinished( fileFullPath );
end
