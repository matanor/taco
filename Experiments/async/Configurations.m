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
        
        ConfigManager.init('C:/technion/theses/matlab/config.mat');
        configManager = ConfigManager.get();
        configManager.createWithDefaultsIfMissing();
        
        folderName = '2012_03_14_1_MRR';
        resultsDir = 'C:/technion/theses/Experiments/WebKB/results/';
        isOnOdin = 0;
        outputManager = OutputManager;
        outputManager.set_currentFolder( [resultsDir folderName]);
        RunMain.run(outputManager, isOnOdin);
    end
    
end

end

