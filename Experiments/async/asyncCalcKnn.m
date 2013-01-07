function asyncCalcKnn( fileFullPath, codeRoot )
    Configurations.setupAsyncRun('asyncCalcKnn', fileFullPath, codeRoot)

    runData = load(fileFullPath);
    inputFileFullPath   = runData.inputFileFullPath;
	instancesRange      = runData.instancesRange;
    K                   = runData.K;

    result = DistributedKnn.calcKnnFromInstances( inputFileFullPath, instancesRange, K);
    
    JobManager.saveJobOutput( result, fileFullPath);
    JobManager.signalJobIsFinished( fileFullPath );

end

