classdef JobManager
    %JOBMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
properties( Constant)
    QUEUE_NAME_STUB = 'QUEUE_NAME_STUB';
    QUEUE_NAME_ALL = 'all.q';
    QUEUE_NAME_MEM = 'mem.q';
    QUEUE_NAME_NEW = 'new_q'; % for new server HERMES
    QUEUE_ID_ALL = 1;
    QUEUE_ID_MEM = 2;
    QUEUE_ID_NEW = 3;
    TOTAL_NUM_QUEUES = 3;
end

methods (Static)
    
    %% createJob
    
    function job = createJob(fileFullPath, functionName, outputManager)
        
        JobManager.signalJobIsStarting( fileFullPath );
        
        [~, fileName, ~] = fileparts(fileFullPath);
        
        runName     = fileName;
        codeRoot    = outputManager.m_codeRoot;
        outputFile  = outputManager.createFileNameAtCurrentFolder([fileName '.output.txt']);
        errorFile   = outputManager.createFileNameAtCurrentFolder([fileName '.error.txt']);

        shellScriptPath  = JobManager.prepareScriptFile...
                               (fileFullPath, functionName, codeRoot);

        queueNameSwitch         = ' -q ';
        runName = runName(1:15);

        command = ['qsub -N ' runName ...
                   queueNameSwitch JobManager.QUEUE_NAME_STUB ...
                   ' -o ' outputFile ...
                   ' -e ' errorFile ...
                   ' ' shellScriptPath ];

        job = Job;
        job.startCommand = command;
        job.fileFullPath = fileFullPath;
        job.logFile      = JobManager.logFileFullPath( fileFullPath );
    end
    
    %% prepareScriptFile
    %  For the new PBS queue system on hermes, 'qsub' a script file. This is 
    %  because directly invoking the matlab starts in the default user
    %  directory, and is unable to find the function to run.
    %  the script content is:
    %  cd <startDirectory> (the directory that contains the function to run)
    %  matlab -nodesktop -r "<functionName>('<jobFileFullPath>','<codeRoot>')" -logfile  <logFilePath>
    
    function R = prepareScriptFile( fileFullPath, ...
                                    functionName, codeRoot)
        logFile         = JobManager.logFileFullPath        ( fileFullPath );
        shellScriptPath = JobManager.shellScriptFileFullPath( fileFullPath );
        asyncCodeFolder = '/Experiments/async';
        startDirectory  = [codeRoot asyncCodeFolder];
        
        schellScript = fopen(shellScriptPath, 'w');
        cdLine =     ['cd  ' startDirectory];
        matlabLine = [' matlab -nodesktop -r "' functionName '(''' ...
                        fileFullPath ''',''' codeRoot ''')" -logfile ' logFile ];
        fprintf(schellScript, [cdLine       '\n']);
        fprintf(schellScript, [matlabLine   '\n']);
        fclose(schellScript);
        R = shellScriptPath;
    end
    
    %% Documentation for Sun Grid Engine switched (odin)
    %  -b Gives the user the possibility to  indicate  explicitly
    %     whether  command should be treated as binary or script.
    %     If the value of -b is  'y',  then  command   may  be  a
    %     binary  or script. 
    
    %% logFileFullPath
    
    function r = logFileFullPath( jobFileFullPath )
        r = [jobFileFullPath '.matlab.log'];
    end
    
    %% shellScriptFileFullPath
    
    function r = shellScriptFileFullPath( jobFileFullPath )
        r = [jobFileFullPath '.sh'];
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
        EXIST_RETURN_STATUS_FILE_EXITS = 2;
        finishedFileFullPath = JobManager.finishedFileFullPath(jobFileFullPath);
        r = (EXIST_RETURN_STATUS_FILE_EXITS == exist(finishedFileFullPath, 'file'));
    end
    
    %% signalJobIsStarting
    
    function signalJobIsStarting( jobFileFullPath )
        configManager = ConfigManager.get();
        config = JobManager.loadConfig(configManager);
        finishedFileFullPath = JobManager.finishedFileFullPath(jobFileFullPath);
        [~, jobName, ~] = fileparts(jobFileFullPath);
        if exist(finishedFileFullPath, 'file')
            Logger.log(['JobManager::signalJobIsStarting. ' ...
                        'Output for job ' jobName ' already exist']);
            if config.resetJobs
                Logger.log(['JobManager::signalJobIsStarting. ' ...
                            'Reseting job ' jobName]);
                FileHelper.deleteFile(finishedFileFullPath);
                logFileFullPath = JobManager.logFileFullPath( jobFileFullPath );
                FileHelper.deleteFile(logFileFullPath);
            else
                Logger.log(['JobManager::signalJobIsStarting. ' ...
                            'job ' jobName ' will be skipped. Existing output used.']);
            end
        end
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
    
    function R = startJobs( jobsCollection, maxNumJobsToStart, queueName )
        numInputJobs = length(jobsCollection) ;
        lastJobToStartIndex = min(numInputJobs, maxNumJobsToStart);
        Logger.log(['Starting ' num2str(lastJobToStartIndex ) ' jobs on queue ' num2str(queueName)]);
        started = [];
        for job_i=1:lastJobToStartIndex
            jobToStart = jobsCollection(job_i);
            jobStatus = jobToStart.checkJobStatus();
            if ~isempty(jobToStart.startCommand)
                % Set the queue that the job belongs to.
                jobToStart.startCommand = strrep(jobToStart.startCommand, JobManager.QUEUE_NAME_STUB, queueName);
            %else
                % we are in dektop simulation mode - this is why the start
                % command is empty
            end
            % In simulation (non-asyncrounous mode) the jobs are
            % run syncrounsly so they may have been finished and should
            % never be started
            % Also possible that we want to use existing output from 
            % previously run jobs
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
    
    %% loadConfig
    
    function config = loadConfig(configManager)
        config = configManager.read();
        maxJobs(JobManager.QUEUE_ID_ALL) = config.maxJobs.all_queue;
        maxJobs(JobManager.QUEUE_ID_MEM) = config.maxJobs.mem_queue;
        maxJobs(JobManager.QUEUE_ID_NEW) = config.maxJobs.new_queue;
        config.maxJobs = maxJobs.';
    end
    
    %% queueIDtoName
    
    function name = queueIDtoName(id)
        switch id
            case JobManager.QUEUE_ID_ALL
                name = JobManager.QUEUE_NAME_ALL;
            case JobManager.QUEUE_ID_MEM
                name = JobManager.QUEUE_NAME_MEM; 
            case JobManager.QUEUE_ID_NEW
                name = JobManager.QUEUE_NAME_NEW;
            otherwise
                Logger.log(['queueIDtoName::Error. unknown queue ID ' ...
                        num2str( id ) ]);
        end                
    end
    
    %% executeJobs
    
    function executeJobs( jobsCollection )
        configManager = ConfigManager.get();
        
        config = JobManager.loadConfig(configManager);
        maxJobs = config.maxJobs;
        
        sleepIntervalInSeconds = 30;
        finished = isempty(jobsCollection);
        
        numQueues = JobManager.TOTAL_NUM_QUEUES;
        
        runningJobs = cell(numQueues,1);
        
        while ~finished
            idleTimoutInMinutes = config.jobTimeoutInMinutes;
            idleTimeoutInSeconds = idleTimoutInMinutes * 60;
            idleTimeout = idleTimeoutInSeconds / sleepIntervalInSeconds;
            
            numRunningJobsPerQueue = cellfun(@length, runningJobs);
            numJobsToStart = maxJobs - numRunningJobsPerQueue;
            for queue_i=1:numQueues
                queueName = JobManager.queueIDtoName(queue_i);
                numJobsToStartForQueue = numJobsToStart(queue_i);
                runningJobsIDS = JobManager.startJobs...
                                    (jobsCollection, numJobsToStartForQueue, queueName);
                runningJobs{queue_i} = [runningJobs{queue_i};
                                        jobsCollection(runningJobsIDS)]; %#ok<AGROW>
                jobsCollection(runningJobsIDS) = [];
                clear runningJobsIDS;
                
                numRunningJobsPerQueue = cellfun(@length, runningJobs);
                Logger.log(['size(runningJobs) = ' num2str(numRunningJobsPerQueue.')]);
                Logger.log(['size(jobsCollection) = ' num2str(size(jobsCollection))]);
            end

            if ParamsManager.ASYNC_RUNS == 1
                pause(sleepIntervalInSeconds);
            end
            config = JobManager.loadConfig(configManager);
            maxJobs = config.maxJobs;

            Logger.log(['**** Status check ****' ...
                  ' timeout (min) = ' num2str(idleTimoutInMinutes)...
                  ' max jobs = '      num2str(maxJobs.')]);
              
            for queue_i=1:numQueues
                runningJobsInQueue = runningJobs{queue_i};
                finished_jobs = [];
                for job_i=1:length(runningJobsInQueue)
                    job = runningJobsInQueue(job_i);
                    jobStatus = job.checkJobStatus();
                    if jobStatus == Job.JOB_STATUS_FINISHED
                        finished_jobs = [finished_jobs;job_i]; %#ok<AGROW>
                    elseif jobStatus == Job.JOB_STATUS_IDLE && ...
                           job.idleCount > idleTimeout
                        JobManager.restartJob( job );
                    end
                end
                runningJobsInQueue(finished_jobs) = [];
                runningJobs{queue_i} = runningJobsInQueue; %#ok<AGROW>
            end
            finished = (0 == sum(cellfun(@length, runningJobs))) && isempty(jobsCollection);
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
        Logger.log(['JobManager::startJob. start command = "' job.startCommand '"']);
        [status, result] = system(job.startCommand);
        if status ~= 0
            Logger.log(['JobManager::startJob. Error starting job run.'...
                ' file: ' job.name() ' status = ' num2str(status)]);
        end
        job.submitResult = result;
        job.lastLogFileSize = 0;
        job.idleCount = 0;
        Logger.log(['JobManager::startJob. result = ' result]);
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

