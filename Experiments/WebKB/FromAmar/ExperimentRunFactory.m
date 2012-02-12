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
        evaluationParams_allOptions   = paramsManager.evaluationParams_allOptions();

        experimentCollection = [];
        
        numConstructionStructs = length(constructionParams_allOptions);
        progressParams.numExperiments = numConstructionStructs;
        
        for construction_i=1:numConstructionStructs
            constructionParams = constructionParams_allOptions( construction_i );
            constructionParams.classToLabelMap = classToLabelMap;

            disp(['File Name = ' constructionParams.fileName]);
            experimentRun = ExperimentRun;
            experimentRun.set_constructionParams( constructionParams );
            experimentRun.constructGraph();

            numEvaluationOptions = length(evaluationParams_allOptions);
            
            progressParams.experiment_i  = construction_i;
            progressParams.numEvaluations = numEvaluationOptions;
            
            for parameters_run_i=1:numEvaluationOptions
                progressParams.evaluation_i = parameters_run_i;
                outputManager.stepIntoFolder(['Parameters_run_' num2str(parameters_run_i)]);
                
                parametersRun    = experimentRun.createEvaluationRun();
                
                evaluationParams = evaluationParams_allOptions(parameters_run_i);
                evaluationParamsString = Utilities.StructToStringConverter(evaluationParams);
                disp(['Evaluation Params. ' evaluationParamsString]);
                parametersRun.set_evaluationParams( evaluationParams );
                
                % this will create the training split
                parametersRun.createTrunsductionSplit();

                ExperimentRunFactory.runOptimizationJobs_allAlgorithms...
                    ( parametersRun, paramsManager, progressParams, ...
                      algorithmsToRun, outputManager);
                  
                optimalParams = ExperimentRunFactory.searchForOptimalParams...
                    ( parametersRun, paramsManager, algorithmsToRun, outputManager );

                % run evaluations

                ExperimentRunFactory.runEvaluations...
                    ( parametersRun, progressParams, optimalParams, ...
                      algorithmsToRun, outputManager);

                experimentRun.addParameterRun( parametersRun );
                outputManager.moveUpOneDirectory();
            end
            experimentCollection = [experimentCollection; experimentRun ]; %#ok<AGROW>
        end
    
    R = experimentCollection;
    end
    
    %% searchForOptimalParams
    
    function R = searchForOptimalParams(parametersRun, paramsManager, algorithmsToRun, outputManager)
        disp('****** Searching for optimal parameter *****')
        optimizationEvaluationMethods = parametersRun.optimizationMethodsCollection();
        jobsToWaitFor = [];
        for algorithm_i=algorithmsToRun.algorithmsRange()
            if paramsManager.shouldOptimize( algorithm_i )
                for evaluation_method_i=optimizationEvaluationMethods
                    optimizationJobNames = parametersRun.get_optimizationJobNames_perAlgorithm(algorithm_i);
                    job = ExperimentRunFactory.searchAndSaveOptimalParams...
                        (optimizationJobNames, algorithm_i, evaluation_method_i, outputManager);
                    optimalJobs{evaluation_method_i,algorithm_i} = job; %#ok<AGROW>
                    jobsToWaitFor = [jobsToWaitFor; job]; %#ok<AGROW>
                end
            else
                optimal = paramsManager.optimizationParams_allOptions(algorithm_i);
                optimal = ExperimentRunFactory.combineOptimizationAndNonOptimizationParams...
                            (optimal, parametersRun);
                for evaluation_method_i=optimizationEvaluationMethods
                    ExperimentRunFactory.printOptimal...
                        (optimal, algorithm_i, evaluation_method_i );
                    optimalParams{evaluation_method_i,algorithm_i} = optimal; %#ok<AGROW>
                end
            end
        end
        
        JobManager.waitForJobs( jobsToWaitFor );
        
        for algorithm_i=algorithmsToRun.algorithmsRange()
            if paramsManager.shouldOptimize( algorithm_i )
                for evaluation_method_i=optimizationEvaluationMethods
                    job = optimalJobs{evaluation_method_i,algorithm_i};
                    optimal = JobManager.loadJobOutput(job.fileFullPath);
                    ExperimentRunFactory.printOptimal...
                        (optimal, algorithm_i, evaluation_method_i );
                    optimalParams{evaluation_method_i,algorithm_i} = optimal; %#ok<AGROW>
                end
            end
        end
        R = optimalParams;
    end
    
    %% printOptimal
    
    function printOptimal(optimal, algorithm_i, evaluation_method_i) 
        optimalString = Utilities.StructToStringConverter(optimal);
        algorithmName = AlgorithmTypeToStringConverter.convert( algorithm_i );
        evaluationMethodName = OptimizationMethodToStringConverter.convert(evaluation_method_i);
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
           job = JobManager.scheduleJob(fileFullPath, 'asyncEvaluateOptimizations', outputManager);
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
        optimal = EvaluationRun.calcOptimalParams(optimizationRuns, algorithmType, optimizeBy);
        optimalString = Utilities.StructToStringConverter(optimal);
        algorithmName = AlgorithmTypeToStringConverter.convert( algorithmType );
        disp(['algorithm = ' algorithmName ...
              '. optimal params: ' optimalString]);
    end
    
    %% runEvaluations
    
    function runEvaluations(parametersRun,   progressParams, optimalParamsAllMethods, ...
                            algorithmsToRun, outputManager)
        disp('******** Running Evaluations ********');
        numEvaluationRuns = parametersRun.get_evaluationParams().numEvaluationRuns;
        progressParams.numEvaluationRuns = numEvaluationRuns;
        optimizeByMethods = parametersRun.get_evaluationParams().optimizeByCollection;
        
        evaluationJobs = [];
        for optimization_method_i=optimizeByMethods
            progressParams.optimization_method_i = optimization_method_i;
            evaluationJobNamesPerMethod = [];
            outputManager.startEvaluationRun(optimization_method_i);
            for algorithm_i=algorithmsToRun.algorithmsRange()
                optimalParams{algorithm_i} = ...
                    optimalParamsAllMethods{optimization_method_i,algorithm_i}; %#ok<AGROW>
            end
            for evaluation_run_i=1:numEvaluationRuns
                progressParams.evaluation_run_i = evaluation_run_i;
                ExperimentRunFactory.displayEvaluationProgress(progressParams);
                % this will create a test split
                parametersRun.createTrunsductionSplit();

                singleRunFactory = parametersRun.createSingleRunFactory();
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
        JobManager.waitForJobs(evaluationJobs);
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
        singleRunFactory     = parametersRun.createSingleRunFactory();
        optimizationJobNames = ExperimentRunFactory.runOptionsCollection...
                (singleRunFactory, optimizationParams_allOptions, ...
                 progressParams  , algorithmType, outputManager);
        parametersRun.setParameterTuningRunsJobNames(algorithmType, optimizationJobNames);
    end

    %% combineOptimizationAndNonOptimizationParams
    
    function R = combineOptimizationAndNonOptimizationParams...
            (optimizationParams_allOptions, parametersRun)
        nonOptimizationParams = parametersRun.get_evaluationParams();
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
        
        JobManager.waitForJobs( optionsJobs );
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