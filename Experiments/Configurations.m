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
        
        folderName = '2012_02_09_1 multiple_parameter_evaluations_per_experiment';
        resultsDir = 'C:/technion/theses/Experiments/WebKB/results/';
        isOnOdin = 0;
        outputManager = OutputManager;
        outputManager.set_currentFolder( [resultsDir folderName]);
        RunMain.run(outputManager, isOnOdin);
    end
    
end

end

