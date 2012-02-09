function asyncPlotResults(fileFullPath, codeRoot)
    Configurations.setupAsyncRun('asyncPlotResults', fileFullPath, codeRoot)    

    runData = load(fileFullPath);
    experimentRuns      = runData.experimentRuns;
    outputManager       = runData.outputManager;
    
    RunMain.plotResults(experimentRuns, outputManager);
    
    JobManager.signalJobIsFinished( fileFullPath );
end

