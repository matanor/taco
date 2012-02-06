classdef Configurations
    %CONFIGURATIONS Summary of this class goes here
    %   Detailed explanation goes here
    
methods (Static)
    
    %% clearEverything
    
    function clearEverything()
        clear classes;
        clear all;
    end
    
    %% runOnDesktop
    
    function runOnDesktop()
        Configurations.clearEverything();
        
        folderName = '2012_02_06_3 useGraphHeuristics experiment new code';
        resultsDir = 'C:\technion\theses\Experiments\WebKB\results\';
        isOnOdin = 0;
        RunMain.run(resultsDir, folderName, isOnOdin);
    end
    
    %% runOnOdin
    
    function runOnOdin(folderName)
        Configurations.clearEverything();

        codeRoot = '/u/matanorb/matlab';
        codeFolders = genpath(codeRoot);
        addpath(codeFolders);

        resultsDir = '/u/matanorb/experiments/webkb/results/';
        isOnOdin = 1;
        RunMain.run(resultsDir, folderName, isOnOdin);
    end
    
end

end

