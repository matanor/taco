function runOnOdin(folderName)
%RUNONODIN Summary of this function goes here
%   Detailed explanation goes here
    disp('runOnOdin');
    Configurations.clearEverything();

    codeRoot = '/u/matanorb/matlab';
    codeFolders = genpath(codeRoot);
    addpath(codeFolders);

    resultsDir = '/u/matanorb/experiments/webkb/results/';
    isOnOdin = 1;
    RunMain.run(resultsDir, folderName, isOnOdin);

end

