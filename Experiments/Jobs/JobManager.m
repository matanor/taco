classdef JobManager
    %JOBMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
methods (Static)
    
    %% createJob
    
    function job = createJob(fileFullPath, functionName, outputManager)
        
        JobManager.signalJobIsStarting( fileFullPath );
        
        [~, fileName, ~] = fileparts(fileFullPath);
        
        runName     = fileName;
        codeRoot    = outputManager.m_codeRoot;
        outputFile  = outputManager.createFileNameAtCurrentFolder([fileName '.output.txt']);
        errorFile   = outputManager.createFileNameAtCurrentFolder([fileName '.error.txt']);
        logFile     = JobManager.logFileFullPath( fileFullPath );
        asyncCodeFolder = '/Experiments/async';
        if ParamsManager.USE_MEM_QUEUE
            queueName = 'mem.q';
        else
            queueName = 'all.q';
        end
        command = ['qsub -N ' runName ' -wd ' codeRoot asyncCodeFolder ' -q ' queueName ' -b y -o ' ...
                   outputFile ' -e ' errorFile ' "matlab -nodesktop -r "\""' functionName '(''' ...
                   fileFullPath ''',''' codeRoot ''')"\"" -logfile ' logFile '"' ];
        
        job = Job;
        job.startCommand = command;
        job.fileFullPath = fileFullPath;
        job.logFile = logFile;
    end
    
    %% logFileFullPath
    
    function r = logFileFullPath( jobFileFullPath )
        r = [jobFileFullPath '.matlab.log'];
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
        FileHelper.deleteFile(finishedFileFullPath);
        logFileFullPath = JobManager.logFileFullPath( jobFileFullPath );
        FileHelper.deleteFile(logFileFullPath);
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
    
    %% startJobs
    
    function R = startJobs( jobsCollection, maxNumJobsToStart )
        numInputJobs = length(jobsCollection) ;
        lastJobToStartIndex = min(numInputJobs, maxNumJobsToStart);
        Logger.log(['Starting ' num2str(lastJobToStartIndex ) ' jobs']);
        started = [];
        for job_i=1:lastJobToStartIndex
            jobToStart = jobsCollection(job_i);
            jobStatus = jobToStart.checkJobStatus();
            % In simulation (non-asyncrounous mode) the jobs are
            % run syncrounsly so they nay have been finished and should
            % never be started
            if jobStatus ~= Job.JOB_STATUS_FINISHED
                JobManager.startJob( jobToStart );
            end
            started = [started; job_i]; %#ok<AGROW>
        end
        if ~isempty(started)
            Logger.log('Started job (indices):');
            Logger.log(num2str(started.'));
        end
        R = started;
    end
    
    %% executeJobs
    
    function executeJobs( jobsCollection )
        configManager = ConfigManager.get();
        config = configManager.read();
        
        sleepIntervalInSeconds = 30;
        finished = isempty(jobsCollection);
        
        maxJobs = config.maxJobs;
        runningJobs = [];
        
        while ~finished
            idleTimoutInMinutes = config.jobTimeoutInMinutes;
            idleTimeoutInSeconds = idleTimoutInMinutes * 60;
            idleTimeout = idleTimeoutInSeconds / sleepIntervalInSeconds;
            
            numRunningJobs = length(runningJobs);
            numJobsToStart = maxJobs - numRunningJobs;
            runningJobsIndices = JobManager.startJobs(jobsCollection, numJobsToStart);
            Logger.log(['size(runningJobs) = ' num2str(size(runningJobs))]);
            Logger.log(['size(jobsCollection) = ' num2str(size(jobsCollection))]);
            runningJobs = [runningJobs;jobsCollection(runningJobsIndices)]; %#ok<AGROW>
            jobsCollection(runningJobsIndices) = [];
            numRunningJobs = length(runningJobs);

            if ParamsManager.ASYNC_RUNS == 1
                pause(sleepIntervalInSeconds);
            end
            config = configManager.read();
            maxJobs = config.maxJobs;

            finished_jobs = [];
            Logger.log(['**** Status check ****' ...
                  ' timeout (min) = ' num2str(idleTimoutInMinutes)...
                  ' max jobs = '      num2str(maxJobs)]);
            for job_i=1:numRunningJobs
                job = runningJobs(job_i);
                jobStatus = job.checkJobStatus();
                if jobStatus == Job.JOB_STATUS_FINISHED
                    finished_jobs = [finished_jobs;job_i]; %#ok<AGROW>
                elseif jobStatus == Job.JOB_STATUS_IDLE && ...
                       job.idleCount > idleTimeout
                    JobManager.restartJob( job );
                end
            end
            runningJobs(finished_jobs) = [];
            finished = isempty( runningJobs ) && isempty(jobsCollection);
        end
    end  
    
    %% restartJob
    
    function restartJob(job)
        Logger.log(['restarting job "' job.name() '"']);
        JobManager.deleteJob(job);
        JobManager.startJob(job);
    end
    
    %% startJob
    
    function startJob(job)
        Logger.log(['start command = "' job.startCommand '"']);
        [status, result] = system(job.startCommand);
        if status ~= 0
            Logger.log(['Error starting job run. file: ' job.name()...
                  ' status = ' num2str(status)]);
        end
        job.submitResult = result;
        job.lastLogFileSize = 0;
        job.idleCount = 0;
        Logger.log(result);
    end
    
    %% deleteJob
    
    function deleteJob(job)
        id = job.jobID();
        deleteCommand = ['qdel ' num2str(id) ];
        Logger.log(['deleteCommand = "' deleteCommand '"']);
        [status, result] = system(deleteCommand);
        if status ~= 0
            Logger.log(['Error deleting job run. file: ' job.name()...
                  ' status = ' num2str(status)]);
        end
        Logger.log(result);
    end

end
    
end % classdef

