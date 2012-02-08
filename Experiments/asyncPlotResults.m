function asyncPlotResults(fileFullPath, codeRoot)
    Configurations.setupAsyncRun('asyncPlotResults', fileFullPath, codeRoot)    

    runData = load(fileFullPath);
    experimentRuns      = runData.experimentRuns;
    outputProperties    = runData.outputProperties;
    
    RunMain.plotResults(experimentRuns, outputProperties);
    
    JobManager.signalJobIsFinished( fileFullPath );
end

