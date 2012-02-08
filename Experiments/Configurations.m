classdef Configurations
    %CONFIGURATIONS Summary of this class goes here
    %   Detailed explanation goes here
    
methods (Static)
    
    function setupAsyncRun(functionName, fileFullPath, codeRoot)
        disp(functionName);
        Configurations.clearEverything();

        disp(['fileFullPath = ' fileFullPath]);
        disp(['codeRoot = ' codeRoot]);
    
        codeFolders = genpath(codeRoot);
        addpath(codeFolders);
    end
    
    %% clearEverything
    
    function clearEverything()
        clear all;
        clear classes;
    end
    
    %% runOnDesktop
    
    function runOnDesktop()
        Configurations.clearEverything();
        
        folderName = '2012_02_07_2 testing new options - unbalanced';
        resultsDir = 'C:/technion/theses/Experiments/WebKB/results/';
        isOnOdin = 0;
        outputProperties.resultsDir = resultsDir;
        outputProperties.folderName = folderName;
        RunMain.run(outputProperties, isOnOdin);
    end
    
end

end

