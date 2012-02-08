classdef Job < handle
    %JOB Summary of this class goes here
    %   Detailed explanation goes here
    
properties
    command;
    submitResult ;
    fileFullPath;
    logFile;
    lastLogFileSize;
    idleCount;
end
    
properties (Constant)
    JOB_STATUS_FINISHED = 0;
    JOB_STATUS_WORKING = 1;
    JOB_STATUS_IDLE = 2;
end
    
methods (Access = public)
    
    %% name
    
    function R = name(this)
        [~, R, ~] = fileparts(this.fileFullPath);
    end
    
    %% jobID
    
    function R = jobID( this )
        % e.g. result = 'Your job 782218 ("Evaluation.1.5") has been submitted';
        items = textscan(this.result, '%s %s %d %s %s %s %s');
        R = items{3};
    end
    
    %% checkJobStatus
    
    function R = checkJobStatus( this )
        jobFileFullPath = this.fileFullPath;
        if JobManager.isJobFinished(jobFileFullPath)
           [~, fileName, ~] = fileparts(jobFileFullPath);
           disp(['job ' fileName ' has finished']);
           R = Job.JOB_STATUS_FINISHED;
        else
           R = this.anyProgressDone(job);
        end
    end    
    
end

methods (Access=private)
    %% anyProgressDone
    
    function R = anyProgressDone(this)
        logFileInfo         = dir(this.logFile);
        currentLogFileSize  = logFileInfo.bytes;
        if ( currentLogFileSize ~= this.lastLogFileSize) % any progress?
            this.lastLogFileSize = currentLogFileSize;
            this.idleCount = 0;
            R = JobManager.JOB_STATUS_WORKING;
        else
            this.idleCount = this.idleCount + 1;
            R = JobManager.JOB_STATUS_IDLE;
        end
    end
end
    
end % classdef

