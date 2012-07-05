function outputManager = initRunOnOdin( resultsDirectory, codeRoot )
    disp('initRunOnOdin');
    disp(['codeRoot = ' codeRoot]);
    codeFolders = genpath(codeRoot);
    addpath(codeFolders);

    Configurations.clearEverything();
    
    ConfigManager.init([codeRoot '/config.mat']);

    outputManager = OutputManager;
    outputManager.set_currentFolder( resultsDirectory );
    outputManager.m_codeRoot        = codeRoot;
end

