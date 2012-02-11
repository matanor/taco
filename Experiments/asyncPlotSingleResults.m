function asyncPlotSingleResults(fileFullPath, codeRoot)
    Configurations.setupAsyncRun('asyncPlotSingleResults', fileFullPath, codeRoot)    

    runData = load(fileFullPath);
    jobNamesCollection  = runData.jobNamesCollection;
    outputManager       = runData.outputManager;
    format              = runData.format;
    
    RunMain.plotSingleResults(jobNamesCollection, outputManager, format);
    
    JobManager.signalJobIsFinished( fileFullPath );
end

