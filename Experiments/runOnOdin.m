function runOnOdin(resultsDirectory, codeRoot)
%RUNONODIN Summary of this function goes here
%   Detailed explanation goes here
    disp('runOnOdin');
    disp(['codeRoot = ' codeRoot]);
    codeFolders = genpath(codeRoot);
    addpath(codeFolders);

    Configurations.clearEverything();
    
    ConfigManager.init([codeRoot '/config.mat']);
    configManager = ConfigManager.get();
    configManager.createWithDefaultsIfMissing();

    isOnOdin = 1;
    outputManager = OutputManager;
    outputManager.set_currentFolder( resultsDirectory );
    outputManager.m_codeRoot        = codeRoot;
    RunMain.run(outputManager, isOnOdin);

end

