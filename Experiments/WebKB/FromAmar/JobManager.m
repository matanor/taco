classdef JobManager
    %JOBMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
methods (Static)
    
    %% scheduleJob
    
    function job = scheduleJob(fileFullPath, functionName, outputProperties)
        
        JobManager.signalJobIsStarting( fileFullPath );
        
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
        [status, submitResult] = system(command);
        if status ~= 0
            disp(['Error scheduling async run. file: ' fileFullPath...
                  ' status = ' num2str(status)]);
        end
        disp(submitResult);
        pause(1);
        
        job = Job;
        job.startCommand = command;
        job.submitResult = submitResult;
        job.fileFullPath = fileFullPath;
        job.logFile = logFile;
        job.lastLogFileSize = 0;
        job.idleCount = 0;
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
    
    function waitForJobs( jobsCollection )
        sleepIntervalInSeconds = 30;
        idleTimeoutInSeconds = 300; % 5 minutes 
        idleTimeout = idleTimeoutInSeconds / sleepIntervalInSeconds;
        while ~isempty( jobsCollection )
            numJobs = length(jobsCollection);
            for job_i=1:numJobs
                job = jobsCollection(job_i);
                jobStatus = job.checkJobStatus();
                if jobStatus == Job.JOB_STATUS_FINISHED
                    jobsCollection(job_i) = [];
                elseif jobStatus == Job.JOB_STATUS_IDLE && ...
                       job.idleCount > idleTimeout
                    JobManager.restartJob( job );
                end
            end
            pause(sleepIntervalInSeconds);
        end
    end  
    
    %% restartJob
    
    function restartJob(job)
        JobManager.deleteCommand(job);
        disp(['restart command = "' job.startCommand '"']);
        [status, result] = system(job.startCommand);
        if status ~= 0
            disp(['Error restarting job run. file: ' job.name()...
                  ' status = ' num2str(status)]);
        end
        disp(result);
    end
    
    %% deleteJob
    
    function deleteJob(job)
        id = job.jobID();
        deleteCommand = ['qdel ' num2str(id) ];
        disp(['deleteCommand = "' deleteCommand '"']);
        [status, result] = system(deleteCommand);
        if status ~= 0
            disp(['Error deleting job run. file: ' job.name()...
                  ' status = ' num2str(status)]);
        end
        disp(result);
    end

end
    
end % classdef

