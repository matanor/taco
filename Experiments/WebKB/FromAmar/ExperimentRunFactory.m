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
                
                singleEvaluation    = experimentRun.createEvaluationRun();
                
                evaluationParams = evaluationParams_allOptions(parameters_run_i);
                evaluationParamsString = Utilities.StructToStringConverter(evaluationParams);
                disp(['Evaluation Params. ' evaluationParamsString]);
                singleEvaluation.set_evaluationParams( evaluationParams );
                
                % this will create the training split
                singleEvaluation.createTrunsductionSplit();

                disp('******** Optimizing ********');
                
                clear optimalParams;
                for algorithm_i=algorithmsToRun.algorithmsRange()
                    algorithmType = algorithm_i;
                    optimalParams{algorithmType} = ...
                        ExperimentRunFactory.optimizeParameters....
                            ( singleEvaluation,    paramsManager,      progressParams, ...
                              algorithmsToRun,     evaluationParams,   algorithmType,...
                              outputManager); %#ok<AGROW>
                end

                % run evaluations

                evaluationJobNames = ExperimentRunFactory.runEvaluations...
                    ( singleEvaluation, progressParams, optimalParams, ...
                      evaluationParams.numEvaluationRuns, algorithmsToRun, outputManager);

                singleEvaluation.setEvaluationRunsJobNames( evaluationJobNames );
                experimentRun.addParameterRun( singleEvaluation );
                outputManager.moveUpOneDirectory();
            end
            experimentCollection = [experimentCollection; experimentRun ]; %#ok<AGROW>
        end
    
    R = experimentCollection;
    end
    
    %% runEvaluations
    
    function R = runEvaluations(singleEvaluation, progressParams, optimalParams, ...
                                numEvaluationRuns, algorithmsToRun, outputManager)
        disp('******** Running Evaluations ********');
        progressParams.numEvaluationRuns = numEvaluationRuns;
        evaluationJobNames = [];
        evaluationJobs = [];
        for evaluation_run_i=1:numEvaluationRuns
            progressParams.evaluation_run_i = evaluation_run_i;
            ExperimentRunFactory.displayEvaluationProgress(progressParams);
            % this will create a test split
            singleEvaluation.createTrunsductionSplit();
            
            singleRunFactory = singleEvaluation.createSingleRunFactory();
            fileName = outputManager.evaluationSingleRunName(progressParams);
            job = ExperimentRunFactory.runAndSaveSingleRun...
                ( singleRunFactory, optimalParams, algorithmsToRun, fileName, outputManager );
            evaluationJobNames = [evaluationJobNames; {fileName}]; %#ok<AGROW>
            evaluationJobs = [evaluationJobs; job]; %#ok<AGROW>
        end
        JobManager.waitForJobs(evaluationJobs);
        disp('all evaluation runs are finished');
        singleEvaluation.setEvaluationRunsJobNames(evaluationJobNames);
        R = evaluationJobNames;
    end
    
    %% optimizeParameters
    
    function optimal = optimizeParameters...
                ( singleEvaluation, paramsManager,    progressParams, ...
                  algorithmsToRun , evaluationParams, algorithmType, outputManager )
        optimal = [];
        if algorithmsToRun.shouldRun( algorithmType )
            algorithmName = AlgorithmTypeToStringConverter.convert( algorithmType );
            singleRunFactory = singleEvaluation.createSingleRunFactory();
            
            optimizationParams_allOptions = ...
                paramsManager.optimizationParams_allOptions( algorithmType );
            
            optimizationParams_allOptions = ...
                paramsManager.addParamsToCollection...
                (optimizationParams_allOptions, evaluationParams);
            
            if length(optimizationParams_allOptions) == 1
                % only one option in optimization options
                disp([algorithmName ': Only 1 optimization option. Skipping optimization runs.']);
                optimal = optimizationParams_allOptions;
                return;
            end
            
            optimizationJobNames = ExperimentRunFactory.runOptionsCollection...
                    (singleRunFactory, optimizationParams_allOptions, ...
                     progressParams  , algorithmType, outputManager);
            singleEvaluation.setParameterTuningRunsJobNames(algorithmType, optimizationJobNames);     
            if ParamsManager.ASYNC_RUNS == 0     
               optimal = ExperimentRunFactory.evaluateAndFindOptimalParams...
                   (optimizationJobNames, algorithmType, evaluationParams.optimizeBy);
            else
               fileFullPath = outputManager.evaluteOptimizationJobName( algorithmType );
               optimizeBy = evaluationParams.optimizeBy; %#ok<NASGU>
               save(fileFullPath, 'optimizationJobNames', 'algorithmType', 'optimizeBy');
               job = JobManager.scheduleJob(fileFullPath, 'asyncEvaluateOptimizations', outputManager);
               JobManager.waitForJobs( job );
               optimal = JobManager.loadJobOutput(fileFullPath);
               % also print optimal value to main script output
               optimalString = Utilities.StructToStringConverter(optimal);
               disp(['algorithm = ' algorithmName ' optimal: ' optimalString]);
            end

        end;
    end
    
    %% evaluateAndFindOptimalParams
    
    function optimal = evaluateAndFindOptimalParams(optimizationJobNames, algorithmType, optimizeBy)
        numOptimizationRuns = length(optimizationJobNames);
        optimizationRuns = [];
        for optimization_run_i=1:numOptimizationRuns
            singleRun = JobManager.loadJobOutput( optimizationJobNames{optimization_run_i} );
            optimizationRuns = [optimizationRuns; singleRun]; %#ok<AGROW>
        end
        
        optimal = EvaluationRun.calcOptimalParams(optimizationRuns, algorithmType, optimizeBy);
        optimalString = Utilities.StructToStringConverter(optimal);
        algorithmName = AlgorithmTypeToStringConverter.convert( algorithmType );
        disp(['algorithm = ' algorithmName ' optimal: ' optimalString]);
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
    
    function job = runAndSaveSingleRun( singleRunFactory, singleOption, ...
                                  algorithmsToRun, fileName, outputManager )
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
        progressString = ...
        [ 'on experiment '   num2str(progressParams.experiment_i)         ...
         ' out of '          num2str(progressParams.numExperiments)        ...
         '. parameter run  ' num2str(progressParams.evaluation_i)         ...
         ' out of '          num2str(progressParams.numEvaluations)       ...
         '. evaluation run ' num2str(progressParams.evaluation_run_i)             ...
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