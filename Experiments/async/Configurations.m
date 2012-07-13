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
        
        ConfigManager.init([codeRoot '/config.mat']);
    end
    
    %% clearEverything
    
    function clearEverything()
        clear all;
        clear classes;
    end
    
    %% runOnDesktop
    
    function runOnDesktop()
        Configurations.clearEverything();
        
        ConfigManager.initOnDesktop();
        
        folderName = '2012_05_10_1_structured';
        resultsDir = 'C:/technion/theses/Experiments/results/';
        isOnOdin = 0;
        outputManager = OutputManager;
        outputManager.set_currentFolder( [resultsDir folderName]);
        RunMain.run(outputManager, isOnOdin);
    end
    
end

end

