function runOnOdin(resultsDirectory, codeRoot)
%RUNONODIN Summary of this function goes here
%   Detailed explanation goes here
    disp('runOnOdin');
    outputManager = initRunOnOdin(resultsDirectory, codeRoot);
    isOnOdin = 1;
    RunMain.run(outputManager, isOnOdin);
end

