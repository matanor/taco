function asyncEvaluationSummary(fileFullPath, codeRoot)
    Configurations.setupAsyncRun('asyncEvaluationSummary', fileFullPath, codeRoot)    

    runData = load(fileFullPath);
    experimentRuns  = runData.experimentRuns;
    outputManager   = runData.outputManager;
    
    RunMain.plotEvaluationSummary(experimentRuns, outputManager);
    
    JobManager.signalJobIsFinished( fileFullPath );
end

