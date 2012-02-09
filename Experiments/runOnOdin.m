function runOnOdin(folderName, codeRoot)
%RUNONODIN Summary of this function goes here
%   Detailed explanation goes here
    disp('runOnOdin');
    Configurations.clearEverything();

    disp(['codeRoot = ' codeRoot]);
    codeFolders = genpath(codeRoot);
    addpath(codeFolders);

    resultsDir = '/u/matanorb/experiments/webkb/results/';
    isOnOdin = 1;
    outputManager = OutputManager;
    outputManager.set_currentFolder( [resultsDir folderName]);
    outputManager.m_codeRoot        = codeRoot;
    RunMain.run(outputManager, isOnOdin);

end

