function asyncEvaluationSummary(fileFullPath, codeRoot)
    Configurations.setupAsyncRun('asyncEvaluationSummary', fileFullPath, codeRoot)    

    runData = load(fileFullPath);
    experimentRuns  = runData.experimentRuns;
    
    RunMain.plotEvaluationSummary(experimentRuns);
    
    JobManager.signalJobIsFinished( fileFullPath );
end

