classdef ExperimentRunFactory < handle

properties (Access = public)
    m_paramsManager;
    m_outputManager;
end
    
methods (Access = public)
    
    %% constructor
    
    function this = ExperimentRunFactory( paramsManager, outputManager )
        this.m_paramsManager = paramsManager;
        this.m_outputManager = outputManager;
    end
    
    %% run
    
    function R = run(this, algorithmsToRun)

        % define the classes we use

%         classToLabelMap = [ 1  1;
%                             4 -1 ];
                        
        classToLabelMap = [ 1  1;
                            2  2
                            3  3
                            4  4];
              
        %
        constructionParams_allOptions = this.m_paramsManager.constructionParams_allOptions();
        parameterValues_allOptions    = this.m_paramsManager.parameterValues_allOptions();
        
        experimentCollection = [];
        
        numConstructionStructs = length(constructionParams_allOptions);
        numEvaluationOptions   = length(parameterValues_allOptions);
        progressParams = ProgressManager(numConstructionStructs, numEvaluationOptions);
        
        for construction_i=1:numConstructionStructs
            this.m_outputManager.startExperimentRun(construction_i);
            constructionParams = constructionParams_allOptions( construction_i );
            constructionParams.classToLabelMap = classToLabelMap;

            disp(['File Name = ' constructionParams.fileName]);
            experimentRun = ExperimentRun(constructionParams);
            experimentRun.constructGraph();
            trunsductionSetsFileName = this.m_outputManager.trunsductionSetsFileName();
            experimentRun.saveTrunsductionSets( trunsductionSetsFileName );

            progressParams.set_currentExperiment( construction_i );
            
            for parameters_run_i=1:numEvaluationOptions
                progressParams.set_currentParameterRun( parameters_run_i );
                this.m_outputManager.startParametersRun(parameters_run_i);
                
                parameterValues = parameterValues_allOptions(parameters_run_i);
                ExperimentRunFactory.displayParameterValues( parameterValues, constructionParams);
                parametersRun = experimentRun.createParameterRun(parameterValues);

                this.runOptimizationJobs_allAlgorithms...
                    ( parametersRun, progressParams, algorithmsToRun);
                  
                experimentRun.addParameterRun( parametersRun );
                this.m_outputManager.moveUpOneDirectory();
            end
            experimentCollection = [experimentCollection; experimentRun ]; %#ok<AGROW>
            this.m_outputManager.moveUpOneDirectory();
        end
        
        this.runAllEvaluations( experimentCollection, progressParams, algorithmsToRun );
        
        R = experimentCollection;
    end
    
    %% runAllEvaluations
    
    function runAllEvaluations( this, experimentCollection, progressParams, algorithmsToRun )
        numExperiments = numel(experimentCollection);
        for construction_i=1:numExperiments
            this.m_outputManager.startExperimentRun(construction_i);
            experimentRun = experimentCollection(construction_i);            
            progressParams.set_currentExperiment( construction_i );
            
            numParameterRuns = experimentRun.numParameterRuns();
            for parameters_run_i=1:numParameterRuns
                progressParams.set_currentParameterRun( parameters_run_i );
                progressParams.displayExperimentAndParameterRun();
                
                this.m_outputManager.startParametersRun(parameters_run_i);
                
                parametersRun = experimentRun.getParameterRun(parameters_run_i);
                
                this.searchForOptimalParams( parametersRun, algorithmsToRun );
                this.runEvaluations( parametersRun, progressParams, algorithmsToRun);
                  
                this.m_outputManager.moveUpOneDirectory();
            end
            this.m_outputManager.moveUpOneDirectory();
        end
    end
    
    %% searchForOptimalParams
    
    function searchForOptimalParams(this, parametersRun, algorithmsToRun)
        disp('****** Searching for optimal parameter *****')
        optimizationEvaluationMethods = parametersRun.optimizationMethodsCollection();
        evaluateOptimizationJobs = [];
        for algorithm_i=algorithmsToRun.algorithmsRange()
            for optimization_method_i=optimizationEvaluationMethods
                if this.m_paramsManager.shouldOptimize( algorithm_i, optimization_method_i )
                    optimizationJobNames = parametersRun.get_optimizationJobNames_perAlgorithm(algorithm_i);
                    job = this.searchAndSaveOptimalParams...
                        (optimizationJobNames, algorithm_i, optimization_method_i);
                    optimalJobs{optimization_method_i,algorithm_i} = job; %#ok<AGROW>
                    evaluateOptimizationJobs = [evaluateOptimizationJobs; job]; %#ok<AGROW>
                else
                    optimal = this.m_paramsManager.defaultParams(algorithm_i, optimization_method_i);
                    optimal = ExperimentRunFactory.combineOptimizationAndNonOptimizationParams...
                            (optimal, parametersRun);
                    ExperimentRunFactory.printOptimal(optimal, algorithm_i, optimization_method_i );
                    optimalParams{optimization_method_i,algorithm_i}.values = optimal; %#ok<AGROW>
                    optimalParams{optimization_method_i,algorithm_i}.avgPRBEP = 1; %#ok<AGROW>
                    optimalParams{optimization_method_i,algorithm_i}.avgAccuracy = 1; %#ok<AGROW>
                    optimalParams{optimization_method_i,algorithm_i}.MRR = 1; %#ok<AGROW>
                end
            end
        end
        
        JobManager.executeJobs( evaluateOptimizationJobs );
        
        for algorithm_i=algorithmsToRun.algorithmsRange()
            for optimization_method_i=optimizationEvaluationMethods
                if this.m_paramsManager.shouldOptimize( algorithm_i, optimization_method_i )
                    job = optimalJobs{optimization_method_i,algorithm_i};
                    optimal = JobManager.loadJobOutput(job.fileFullPath);
                    ExperimentRunFactory.printOptimal...
                        (optimal.values, algorithm_i, optimization_method_i );
                    optimalParams{optimization_method_i,algorithm_i} = optimal; %#ok<AGROW>
                end
            end
        end
        
        parametersRun.set_optimalParams(optimalParams);
    end

    %% runOptimizationJobs_allAlgorithms
    
    function runOptimizationJobs_allAlgorithms...
            (this, parametersRun, progressParams, algorithmsToRun)
        disp('******** Optimizing ********');
                
        for algorithm_i=algorithmsToRun.algorithmsRange()
            this.runOptimizationJobs_oneAlgorithm....
                    ( parametersRun, progressParams, algorithm_i);
        end
    end
    
    %% searchAndSaveOptimalParams
    
    function job = searchAndSaveOptimalParams...
            (this, optimizationJobNames, algorithmType, optimizeBy)
        fileFullPath = this.m_outputManager.evaluteOptimizationJobName( algorithmType, optimizeBy );
        if ParamsManager.ASYNC_RUNS == 0     
           optimal = ExperimentRunFactory.evaluateAndFindOptimalParams...
               (optimizationJobNames, algorithmType, optimizeBy);
           JobManager.saveJobOutput( optimal, fileFullPath);
           JobManager.signalJobIsFinished( fileFullPath );
           job = Job;
           job.fileFullPath = fileFullPath;
        else
           save(fileFullPath, 'optimizationJobNames', 'algorithmType', 'optimizeBy');
           job = JobManager.createJob(fileFullPath, 'asyncEvaluateOptimizations', this.m_outputManager);
        end
    end
    
    %% runEvaluations
    
    function runEvaluations(this, parametersRun,   progressParams, ...
                            algorithmsToRun)
        disp('******** Running Evaluations ********');
        numEvaluationRuns = parametersRun.numEvaluationRuns();
        progressParams.set_numEvaluationRuns( numEvaluationRuns );
        optimizeByMethods = parametersRun.optimizationMethodsCollection();
        
        evaluationJobs = [];
        for optimization_method_i=optimizeByMethods
            progressParams.set_currentOptimizationMethod( optimization_method_i );
            evaluationJobNamesPerMethod = [];
            this.m_outputManager.startEvaluationRun(optimization_method_i);
            optimalParams = parametersRun.get_optimalParams_perOptimizationMethod...
                                (optimization_method_i, algorithmsToRun);
            for evaluation_run_i=1:numEvaluationRuns
                progressParams.set_currentEvaluationRun( evaluation_run_i );
                progressParams.displayEvaluationProgress();

                singleRunFactory = parametersRun.createEvaluationRunFactory(evaluation_run_i);
                fileName = this.m_outputManager.evaluationSingleRunName...
                    (progressParams, optimization_method_i);
                job = this.runAndSaveSingleRun...
                    ( singleRunFactory, optimalParams, algorithmsToRun, fileName );
                evaluationJobNamesPerMethod = [evaluationJobNamesPerMethod; {fileName}]; %#ok<AGROW>
                evaluationJobs = [evaluationJobs; job]; %#ok<AGROW>
            end
            
            this.m_outputManager.moveUpOneDirectory();
            evaluationJobNames{optimization_method_i} = evaluationJobNamesPerMethod; %#ok<AGROW>
        end
        JobManager.executeJobs(evaluationJobs);
        disp('all evaluation runs are finished');
        parametersRun.setEvaluationRunsJobNames(evaluationJobNames);
    end
    
    
    %% runOptimizationJobs_oneAlgorithm
    
    function runOptimizationJobs_oneAlgorithm...
                ( this, parametersRun, progressParams, algorithmType )
        % get all optimization options for this algorithm
        optimizationParams_allOptions = ...
            this.m_paramsManager.optimizationParams_allOptions( algorithmType );

        if length(optimizationParams_allOptions) == 1
            % only one option in optimization options
            algorithmName           = AlgorithmTypeToStringConverter.convert( algorithmType );
            disp([algorithmName ': Only 1 optimization option. Skipping optimization jobs.']);
            return;
        end
        
        optimizationParams_allOptions = ...
            ExperimentRunFactory.combineOptimizationAndNonOptimizationParams...
                (optimizationParams_allOptions, parametersRun);

        % run optimization jobs
        optimization_set_i = 1; % currently optimizing on only 1 trunsduction set.
        singleRunFactory     = parametersRun.createOptimizationRunFactory( optimization_set_i );
        optimizationJobNames = this.runOptionsCollection...
                (singleRunFactory, optimizationParams_allOptions, ...
                 progressParams  , algorithmType);
        parametersRun.setParameterTuningRunsJobNames(algorithmType, optimizationJobNames);
    end

    %% runOptionsCollection
    
    function R = runOptionsCollection...
            (this, singleRunFactory, optionsCollection,...
             progressParams  , algorithmType)
        ticID = tic;
        numOptions = length(optionsCollection);
        progressParams.set_numOptimizationRuns( numOptions );

        algorithmsToRun = AlgorithmsCollection;
        algorithmsToRun.setRun(algorithmType);
            
        optionsJobNames = [];
        optionsJobs = [];
        for params_i=1:numOptions
            progressParams.set_currentOptimizationRun( params_i );
            progressParams.displayOptimizationProgress();

            clear singleOption;
            singleOption{algorithmType} = optionsCollection(params_i); %#ok<AGROW>

            fileName = this.m_outputManager.optimizationSingleRunName...
                    (progressParams, algorithmType);

            job = this.runAndSaveSingleRun...
                ( singleRunFactory, singleOption, algorithmsToRun, fileName);

            optionsJobNames = [optionsJobNames;{fileName}]; %#ok<AGROW>
            optionsJobs = [optionsJobs; job]; %#ok<AGROW>
        end
        
        JobManager.executeJobs( optionsJobs );
        disp('all options collection runs are finished');
        
        toc(ticID);
        R = optionsJobNames;
    end
    
    %% runAndSaveSingleRun
    
    function job = runAndSaveSingleRun...
        ( this, singleRunFactory, singleOption, algorithmsToRun, fileName )
        if ParamsManager.ASYNC_RUNS == 0
            singleRun = singleRunFactory.run(singleOption, algorithmsToRun );
            JobManager.saveJobOutput( singleRun, fileName);
            JobManager.signalJobIsFinished( fileName );
            job = Job;
            job.fileFullPath = fileName;
        else
            job = singleRunFactory.scheduleAsyncRun...
                (singleOption, algorithmsToRun, ...
                 fileName, this.m_outputManager );
        end
    end
end
    
methods (Static)
    
    %% evaluateAndFindOptimalParams
    
    function optimal = evaluateAndFindOptimalParams...
            (optimizationJobNames, algorithmType, optimizeBy)
        % load all optimization runs
        numOptimizationRuns = length(optimizationJobNames);
        optimizationRuns = [];
        for optimization_run_i=1:numOptimizationRuns
            singleRun = JobManager.loadJobOutput( optimizationJobNames{optimization_run_i} );
            optimizationRuns = [optimizationRuns; singleRun]; %#ok<AGROW>
        end
        
        % evaluate arccording to optimization criterion
        optimal = ParameterRun.calcOptimalParams...
            (optimizationRuns, algorithmType, optimizeBy);
        ExperimentRunFactory.printOptimal(optimal.values, algorithmType, optimizeBy );
    end
    
    %% combineOptimizationAndNonOptimizationParams
    
    function R = combineOptimizationAndNonOptimizationParams...
            (optimizationParams_allOptions, parametersRun)
        nonOptimizationParams = parametersRun.get_paramValues();
        % combine optimization options with current run parameters
        R = ParamsManager.addParamsToCollection...
            (optimizationParams_allOptions, nonOptimizationParams);
    end
    
    %% displayParameterValues
    
    function displayParameterValues(parameterValues, constructionParams)
        parameterValuesString    = Utilities.StructToStringConverter(parameterValues);
        constructionParamsString = Utilities.StructToStringConverter(constructionParams);
        disp(['Parameter run values. ' constructionParamsString ' ' parameterValuesString]);
    end
    
    %% printOptimal
    
    function printOptimal(optimal, algorithm_i, optimization_method_i) 
        optimalString = Utilities.StructToStringConverter(optimal);
        algorithmName = AlgorithmTypeToStringConverter.convert( algorithm_i );
        evaluationMethodName = OptimizationMethodToStringConverter.convert(optimization_method_i);
        disp(['algorithm = '    algorithmName ...
              ' evaluation = '  evaluationMethodName ...
              ' optimal: '      optimalString]);      
    end

end % methods (Static)

end % classdef