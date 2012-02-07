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
    RunMain.run(resultsDir, folderName, isOnOdin);

end

