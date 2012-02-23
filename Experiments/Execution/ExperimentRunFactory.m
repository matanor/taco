classdef ExperimentRunFactory < handle
    
methods (Static)
    
    %% run
    %graphFileName, paramStructs
    function R = run( paramsManager, algorithmsToRun, outputManager)

        % define the classes we use

%         classToLabelMap = [ 1  1;
%                             4 -1 ];
                        
        classToLabelMap = [ 1  1;
                            2  2
                            3  3
                            4  4];
              
        %
        constructionParams_allOptions = paramsManager.constructionParams_allOptions();
        parameterValues_allOptions     = paramsManager.parameterValues_allOptions();

        experimentCollection = [];
        
        numConstructionStructs = length(constructionParams_allOptions);
        progressParams.numExperiments = numConstructionStructs;
        
        for construction_i=1:numConstructionStructs
            outputManager.startExperimentRun(construction_i);
            constructionParams = constructionParams_allOptions( construction_i );
            constructionParams.classToLabelMap = classToLabelMap;

            disp(['File Name = ' constructionParams.fileName]);
            experimentRun = ExperimentRun(constructionParams);
            experimentRun.constructGraph();

            numEvaluationOptions = length(parameterValues_allOptions);
            
            progressParams.experiment_i  = construction_i;
            progressParams.numEvaluations = numEvaluationOptions;
            
            for parameters_run_i=1:numEvaluationOptions
                progressParams.evaluation_i = parameters_run_i;
                outputManager.startParametersRun(parameters_run_i);
                
                parameterValues = parameterValues_allOptions(parameters_run_i);
                ExperimentRunFactory.displayParameterValues( parameterValues, constructionParams);
                parametersRun = experimentRun.createParameterRun(parameterValues);

                ExperimentRunFactory.runOptimizationJobs_allAlgorithms...
                    ( parametersRun, paramsManager, progressParams, ...
                      algorithmsToRun, outputManager);
                  
                ExperimentRunFactory.searchForOptimalParams...
                    ( parametersRun, paramsManager, algorithmsToRun, outputManager );

                % run evaluations

                ExperimentRunFactory.runEvaluations...
                    ( parametersRun, progressParams, ...
                      algorithmsToRun, outputManager);

                experimentRun.addParameterRun( parametersRun );
                outputManager.moveUpOneDirectory();
            end
            experimentCollection = [experimentCollection; experimentRun ]; %#ok<AGROW>
            outputManager.moveUpOneDirectory();
        end
    
    R = experimentCollection;
    end
    
    %% displayParameterValues
    
    function displayParameterValues(parameterValues, constructionParams)
        parameterValuesString    = Utilities.StructToStringConverter(parameterValues);
        constructionParamsString = Utilities.StructToStringConverter(constructionParams);
        disp(['Parameter run values. ' constructionParamsString ' ' parameterValuesString]);
    end
    
    %% searchForOptimalParams
    
    function searchForOptimalParams(parametersRun, paramsManager, algorithmsToRun, outputManager)
        disp('****** Searching for optimal parameter *****')
        optimizationEvaluationMethods = parametersRun.optimizationMethodsCollection();
        jobsToWaitFor = [];
        for algorithm_i=algorithmsToRun.algorithmsRange()
            for optimization_method_i=optimizationEvaluationMethods
                if paramsManager.shouldOptimize( algorithm_i, optimization_method_i )
                    optimizationJobNames = parametersRun.get_optimizationJobNames_perAlgorithm(algorithm_i);
                    job = ExperimentRunFactory.searchAndSaveOptimalParams...
                        (optimizationJobNames, algorithm_i, optimization_method_i, outputManager);
                    optimalJobs{optimization_method_i,algorithm_i} = job; %#ok<AGROW>
                    jobsToWaitFor = [jobsToWaitFor; job]; %#ok<AGROW>
                else
                    optimal = paramsManager.defaultParams(algorithm_i, optimization_method_i);
                    optimal = ExperimentRunFactory.combineOptimizationAndNonOptimizationParams...
                            (optimal, parametersRun);
                    ExperimentRunFactory.printOptimal(optimal, algorithm_i, optimization_method_i );
                    optimalParams{optimization_method_i,algorithm_i}.values = optimal; %#ok<AGROW>
                    optimalParams{optimization_method_i,algorithm_i}.score = 1; %#ok<AGROW>
                end
            end
        end
        
        JobManager.executeJobs( jobsToWaitFor );
        
        for algorithm_i=algorithmsToRun.algorithmsRange()
            for optimization_method_i=optimizationEvaluationMethods
                if paramsManager.shouldOptimize( algorithm_i, optimization_method_i )
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
    
    %% printOptimal
    
    function printOptimal(optimal, algorithm_i, optimization_method_i) 
        optimalString = Utilities.StructToStringConverter(optimal);
        algorithmName = AlgorithmTypeToStringConverter.convert( algorithm_i );
        evaluationMethodName = OptimizationMethodToStringConverter.convert(optimization_method_i);
        disp(['algorithm = '    algorithmName ...
              ' evaluation = '  evaluationMethodName ...
              ' optimal: '      optimalString]);      
    end
    
    %% searchAndSaveOptimalParams
    
    function job = searchAndSaveOptimalParams...
            (optimizationJobNames, algorithmType, optimizeBy, outputManager)
        fileFullPath = outputManager.evaluteOptimizationJobName( algorithmType, optimizeBy );
        if ParamsManager.ASYNC_RUNS == 0     
           optimal = ExperimentRunFactory.evaluateAndFindOptimalParams...
               (optimizationJobNames, algorithmType, optimizeBy);
           JobManager.saveJobOutput( optimal, fileFullPath);
           JobManager.signalJobIsFinished( fileFullPath );
           job = Job;
           job.fileFullPath = fileFullPath;
        else
           save(fileFullPath, 'optimizationJobNames', 'algorithmType', 'optimizeBy');
           job = JobManager.createJob(fileFullPath, 'asyncEvaluateOptimizations', outputManager);
        end
    end
    
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
        optimal = ParameterRun.calcOptimalParams(optimizationRuns, algorithmType, optimizeBy);
        ExperimentRunFactory.printOptimal(optimal.values, algorithmType, optimizeBy );
    end
    
    %% runEvaluations
    
    function runEvaluations(parametersRun,   progressParams, ...
                            algorithmsToRun, outputManager)
        disp('******** Running Evaluations ********');
        numEvaluationRuns = parametersRun.numEvaluationRuns();
        progressParams.numEvaluationRuns = numEvaluationRuns;
        optimizeByMethods = parametersRun.optimizationMethodsCollection();
        
        evaluationJobs = [];
        for optimization_method_i=optimizeByMethods
            progressParams.optimization_method_i = optimization_method_i;
            evaluationJobNamesPerMethod = [];
            outputManager.startEvaluationRun(optimization_method_i);
            optimalParams = parametersRun.get_optimalParams_perOptimizationMethod...
                                (optimization_method_i, algorithmsToRun);
            for evaluation_run_i=1:numEvaluationRuns
                progressParams.evaluation_run_i = evaluation_run_i;
                ExperimentRunFactory.displayEvaluationProgress(progressParams);

                singleRunFactory = parametersRun.createEvaluationRunFactory(evaluation_run_i);
                fileName = outputManager.evaluationSingleRunName...
                    (progressParams, optimization_method_i);
                job = ExperimentRunFactory.runAndSaveSingleRun...
                    ( singleRunFactory, optimalParams, algorithmsToRun, fileName, outputManager );
                evaluationJobNamesPerMethod = [evaluationJobNamesPerMethod; {fileName}]; %#ok<AGROW>
                evaluationJobs = [evaluationJobs; job]; %#ok<AGROW>
            end
            
            outputManager.moveUpOneDirectory();
            evaluationJobNames{optimization_method_i} = evaluationJobNamesPerMethod; %#ok<AGROW>
        end
        JobManager.executeJobs(evaluationJobs);
        disp('all evaluation runs are finished');
        parametersRun.setEvaluationRunsJobNames(evaluationJobNames);
    end
    
    %% runOptimizationJobs_allAlgorithms
    
    function runOptimizationJobs_allAlgorithms...
            (parametersRun,   paramsManager, progressParams, ...
             algorithmsToRun, outputManager)
        disp('******** Optimizing ********');
                
        for algorithm_i=algorithmsToRun.algorithmsRange()
            ExperimentRunFactory.runOptimizationJobs_oneAlgorithm....
                    ( parametersRun,    paramsManager,  progressParams, ...
                      algorithm_i,    outputManager);
        end
    end
    
    %% runOptimizationJobs_oneAlgorithm
    
    function runOptimizationJobs_oneAlgorithm...
                ( parametersRun, paramsManager,    progressParams, ...
                  algorithmType, outputManager )
        % get all optimization options for this algorithm
        optimizationParams_allOptions = ...
            paramsManager.optimizationParams_allOptions( algorithmType );

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
        optimizationJobNames = ExperimentRunFactory.runOptionsCollection...
                (singleRunFactory, optimizationParams_allOptions, ...
                 progressParams  , algorithmType, outputManager);
        parametersRun.setParameterTuningRunsJobNames(algorithmType, optimizationJobNames);
    end

    %% combineOptimizationAndNonOptimizationParams
    
    function R = combineOptimizationAndNonOptimizationParams...
            (optimizationParams_allOptions, parametersRun)
        nonOptimizationParams = parametersRun.get_paramValues();
        % combine optimization options with current run parameters
        R = ParamsManager.addParamsToCollection...
            (optimizationParams_allOptions, nonOptimizationParams);
    end
    
    %% runOptionsCollection
    
    function R = runOptionsCollection...
            (singleRunFactory, optionsCollection,...
             progressParams  , algorithmType, outputManager)
        ticID = tic;
        numOptions = length(optionsCollection);
        progressParams.numParametersOptions = numOptions;

        algorithmsToRun = AlgorithmsCollection;
        algorithmsToRun.setRun(algorithmType);
            
        optionsJobNames = [];
        optionsJobs = [];
        for params_i=1:numOptions
            % Display progress string
            progressParams.params_i = params_i;
            ExperimentRunFactory.displayOptimizationProgress(progressParams);

            clear singleOption;
            singleOption{algorithmType} = optionsCollection(params_i); %#ok<AGROW>

            fileName = outputManager.optimizationSingleRunName...
                    (progressParams, algorithmType);

            job = ExperimentRunFactory.runAndSaveSingleRun...
                ( singleRunFactory, singleOption, algorithmsToRun, fileName, outputManager );

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
        ( singleRunFactory, singleOption, algorithmsToRun, ...
          fileName, outputManager )
        if ParamsManager.ASYNC_RUNS == 0
            singleRun = singleRunFactory.run(singleOption, algorithmsToRun );
            JobManager.saveJobOutput( singleRun, fileName);
            JobManager.signalJobIsFinished( fileName );
            job = Job;
            job.fileFullPath = fileName;
        else
            job = singleRunFactory.scheduleAsyncRun...
                (singleOption, algorithmsToRun, ...
                 fileName, outputManager );
        end
    end

    %% displayEvaluationProgress
    
    function displayEvaluationProgress(progressParams)
        optimizationMethodName = ...
            OptimizationMethodToStringConverter.convert(progressParams.optimization_method_i);
        progressString = ...
        [ 'on experiment '   num2str(progressParams.experiment_i)         ...
         ' out of '          num2str(progressParams.numExperiments)        ...
         '. parameter run  ' num2str(progressParams.evaluation_i)         ...
         ' out of '          num2str(progressParams.numEvaluations)       ...
         '. ' optimizationMethodName ...
         '. evaluation run ' num2str(progressParams.evaluation_run_i)     ...
         ' out of '          num2str(progressParams.numEvaluationRuns) ];

        disp(progressString);
    end
    
    %% displayOptimizationProgress
    
    function displayOptimizationProgress(progressParams)
        progressString = ...
        [ 'on experiment '      num2str(progressParams.experiment_i)         ...
         ' out of '             num2str(progressParams.numExperiments)        ...
         '. parameter run '     num2str(progressParams.evaluation_i)         ...
         ' out of '             num2str(progressParams.numEvaluations)       ...
         '. optimization run '  num2str(progressParams.params_i)             ...
         ' out of '             num2str(progressParams.numParametersOptions) ];

        disp(progressString);
    end
    
    %% removeVertices
    
    function [graph labeledVertices] = removeVertices...
            ( graph, labeledVertices, verticesToRemove )

        numVertices = length(graph.labels);
        verticesID = 1:numVertices;
        
        graph.labels(verticesToRemove) = [];
        graph.weights(verticesToRemove, :) = [];
        graph.weights(:, verticesToRemove) = [];
        verticesID(verticesToRemove) = [];
        
        numVertices = length(graph.labels);

        %oldLabeledVertices = labeledVertices;
        labeledPositions = ismember(verticesID,labeledVertices);
        newVerticesID    = 1:numVertices;
        labeledVertices  = newVerticesID( labeledPositions );
    end

end % methods (Static)

end % classdef