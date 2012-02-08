classdef JobManager
    %JOBMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
methods (Static)
    
    %% scheduleJob
    
    function scheduleJob(fileFullPath, functionName, outputProperties)
        
        JonManager.signalJobIsStarting( fileFullPath );
        
        [~, fileName, ~] = fileparts(fileFullPath);
        
        outputDir   = outputProperties.resultsDir;
        folderName  = outputProperties.folderName;
        runName     = fileName;
        codeRoot    = outputProperties.codeRoot;
        outputFile  = [outputDir folderName '/' fileName '.output.txt'];
        errorFile   = [outputDir folderName '/' fileName '.error.txt'];
        logFile     = [outputDir folderName '/' fileName '.matlab.log'];
        command = ['qsub -N ' runName ' -wd ' codeRoot '/Experiments -q all.q -b y -o ' ...
                   outputFile ' -e ' errorFile ' "matlab -nodesktop -r "\""' functionName '(''' ...
                   fileFullPath ''',''' codeRoot ''')"\"" -logfile ' logFile '"' ];
        disp(['command = "' command '"']);
        [status, result] = system(command);
        if status ~= 0
            disp(['Error scheduling async run. file: ' fileFullPath...
                  ' statuc = ' num2str(status)]);
        end
        disp(result);
        pause(5);
    end
    
    %% finishedFileFullPath
    
    function r = finishedFileFullPath( jobFileFullPath )
        r = [jobFileFullPath '.finished'];
    end
    
    %% outputFileFullPath
    
    function r = outputFileFullPath( jobFileFullPath )
        r = [jobFileFullPath '.out.mat'];
    end
    
    %% isJobFinished
    
    function r = isJobFinished( jobFileFullPath )
        EXIST_RESURN_STATUS_FILE_EXITS = 2;
        finishedFileFullPath = JobManager.finishedFileFullPath(jobFileFullPath);
        r = (EXIST_RESURN_STATUS_FILE_EXITS == exist(finishedFileFullPath, 'file'));
    end
    
    %% signalJobIsStarting
    
    function signalJobIsStarting( jobFileFullPath )
        finishedFileFullPath = JobManager.finishedFileFullPath(jobFileFullPath);
        delete(finishedFileFullPath);
    end
    
    %% signalJobIsFinished
    
    function signalJobIsFinished( jobFileFullPath )
        dummy = 1; %#ok<NASGU>
        finishedFileFullPath = JobManager.finishedFileFullPath(jobFileFullPath);
        save(finishedFileFullPath, 'dummy');
    end
    
    %% saveJobOutput
    
    function saveJobOutput( jobOutput, jobFileFullPath )
        outputFileFullPath = JobManager.outputFileFullPath(jobFileFullPath);
        save(outputFileFullPath, 'jobOutput');
    end
    
    %% loadJobOutput
    
    function jobOutput = loadJobOutput(jobFileFullPath)
        outputFileFullPath = JobManager.outputFileFullPath(jobFileFullPath);
        outputFileData = load(outputFileFullPath);
        jobOutput = outputFileData.jobOutput;
    end
    
    %% waitForJobs
    
    function waitForJobs( jobNamesCollection )
        numJobs = jobNamesCollection;
        sleepIntervalInSeconds = 30;
        for job_i=1:numJobs
            jobFileFullPath = jobNamesCollection{job_i};
            wait = 1;
            while wait
                if JobManager.isJobFinished(jobFileFullPath)
                    wait = 0;
                    [~, fileName, ~] = fileparts(fileFullPath);
                    disp(['job ' fileName ' has finished']);
                else
                   pause(sleepIntervalInSeconds) 
                end
            end
        end
    end
    
end
    
end

