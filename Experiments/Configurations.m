classdef Configurations
    %CONFIGURATIONS Summary of this class goes here
    %   Detailed explanation goes here
    
methods (Static)
    
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
        RunMain.run(resultsDir, folderName, isOnOdin);
    end
    
end

end

