classdef OutputManager < handle
    %OUTPUTMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
properties
    m_currentFolder;
    m_codeRoot;
    m_showSingleRuns;
    m_showAccumulativeLoss;
    m_description;
end

properties (Constant)
    SEPERATOR = '/';
end
    
methods
    %% Constructor
    
    function this = OutputManager()
        this.m_currentFolder = OutputManager.SEPERATOR;
    end
    
    %% set_currentFolder
    
    function set_currentFolder(this, value)
        this.m_currentFolder = value;
        FileHelper.createDirectory( this.m_currentFolder );
    end
    
    %% moveUpOneDirectory
    
    function moveUpOneDirectory(this)
        if strcmp(this.m_currentFolder,this.SEPERATOR)
            disp(['Cannot move up one directory. current = ' ...
                  this.m_currentFolder]);
            return;
        end
        seperator_indices = strfind(this.m_currentFolder, this.SEPERATOR);
        l = length(this.m_currentFolder);
        if seperator_indices(end) == l
            % seperator at end of current folder
            deleteFromPosition = seperator_indices(end-1);
        else
            deleteFromPosition = seperator_indices(end);
        end
        this.m_currentFolder( (deleteFromPosition+1):end ) = [];
    end
    
    %% startExperimentRun
    
    function startExperimentRun(this, experiment_run_i)
        this.stepIntoFolder(['Experiment_run_' num2str(experiment_run_i)]);
    end
    
    %% startParametersRun
    
    function startParametersRun(this, parameters_run_i)  
        this.stepIntoFolder(['Parameters_run_' num2str(parameters_run_i)]);
    end
    
    %% startEvaluationRun
    
    function startEvaluationRun(this, optimization_method_i)
        optimization_method_name = ...
                OptimizationMethodToStringConverter.convert(optimization_method_i);
        this.stepIntoFolder(optimization_method_name);
    end
    
    %% addSeperatorIfMissing
    
    function addSeperatorIfMissing(this)
        if this.m_currentFolder(end) ~= this.SEPERATOR
            this.m_currentFolder = [this.m_currentFolder this.SEPERATOR];
        end
    end
    
    %% stepIntoFolder
    
    function stepIntoFolder(this, folderName)
        this.addSeperatorIfMissing();
        this.m_currentFolder = [this.m_currentFolder folderName '/'];
        FileHelper.createDirectory( this.m_currentFolder );
    end
    
    %% createFileNameAtCurrentFolder
    
    function r = createFileNameAtCurrentFolder(this, fileName)
        this.addSeperatorIfMissing();
        r = [this.m_currentFolder fileName];
    end
    
    %% trunsductionSetsFileName
    
    function r = trunsductionSetsFileName(this)
        r = this.createFileNameAtCurrentFolder('TrunsductionSets.mat');
    end
    
    %% evaluteOptimizationJobName
        
    function r = evaluteOptimizationJobName( this, algorithmType, optimizationMethod )
        algorithmName = AlgorithmTypeToStringConverter.convert(algorithmType);
        optimizationMethodName = OptimizationMethodToStringConverter.convert(optimizationMethod);
        r = this.createFileNameAtCurrentFolder...
            (['EvaluateOptimization.' algorithmName '.' optimizationMethodName '.mat']);
    end
    
    %% evaluationSingleRunName
    
    function r = evaluationSingleRunName(this, progressParams, optimization_method_i)
        optimizationMethodName = OptimizationMethodToStringConverter.convert(optimization_method_i);
        r = this.createFileNameAtCurrentFolder...
            (   ['Evaluation.' num2str(progressParams.evaluation_i) '.' ...
                num2str(progressParams.evaluation_run_i) '.' ...
                optimizationMethodName '.mat']);
        disp(['evaluationSingleRunName = ' r]);
    end
    
    %% optimizationSingleRunName
    
    function r = optimizationSingleRunName(this, progressParams, algorithmType)
        algorithmName = AlgorithmTypeToStringConverter.convert(algorithmType);
        r = this.createFileNameAtCurrentFolder...
            (['Optimization.' num2str(progressParams.evaluation_i) '.' ...
             num2str(progressParams.params_i) '.' algorithmName '.mat']);
         disp(['optimizationSingleRunName = ' r]);
    end
end
    
end

