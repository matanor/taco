classdef ExperimentRunFactory < handle
    
methods (Static)
    
    %% run
    %graphFileName, paramStructs
    function R = run( paramsManager, algorithmsToRun)

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

            for evaluation_i=1:numEvaluationOptions
                progressParams.evaluation_i = evaluation_i;
                
                singleEvaluation    = experimentRun.createEvaluationRun();
                
                evaluationParams = evaluationParams_allOptions(evaluation_i);
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
                              algorithmsToRun,     evaluationParams,   algorithmType   ); %#ok<AGROW>
                end

                % run evaluations
                
                disp('******** Running Evaluations ********');

                progressParams.numEvaluationRuns = evaluationParams.numEvaluationRuns;
                allEvaluationRuns = MultipleRuns;
                for evaluation_run_i=1:evaluationParams.numEvaluationRuns
                    progressParams.evaluation_run_i = evaluation_run_i;
                    ExperimentRunFactory.displayEvaluationProgress(progressParams);
                    % this will create a test split
                    singleEvaluation.createTrunsductionSplit();
                    singleRunFactory = singleEvaluation.createSingleRunFactory();
                    singleRun = singleRunFactory.run(optimalParams, algorithmsToRun );
                    allEvaluationRuns.addRun(singleRun);
                end
                singleEvaluation.setEvaluationRuns( allEvaluationRuns );
                experimentRun.addParameterRun( singleEvaluation );
            end
            experimentCollection = [experimentCollection; experimentRun ]; %#ok<AGROW>
        end
    
    R = experimentCollection;
    end
    
    %% optimizeParameters
    
    function optimal = optimizeParameters...
                ( singleEvaluation, paramsManager,    progressParams, ...
                  algorithmsToRun , evaluationParams, algorithmType )
        optimal = [];
        if algorithmsToRun.shouldRun( algorithmType )
            
            singleRunFactory = singleEvaluation.createSingleRunFactory();
            
            optimizationParams_allOptions = ...
                paramsManager.optimizationParams_allOptions( algorithmType );
            
            optimizationParams_allOptions = ...
                paramsManager.addParamsToCollection...
                (optimizationParams_allOptions, evaluationParams);
            
            if length(optimizationParams_allOptions) == 1
                % only one option in optimization options
                disp('Only 1 optimization option. Skipping optimization runs.');
                optimal = optimizationParams_allOptions;
                return;
            end
            
            optimizationRuns = ExperimentRunFactory.runOptionsCollection...
                    (singleRunFactory, optimizationParams_allOptions, ...
                     progressParams  , algorithmType);
                 
            singleEvaluation.setParameterTuningRuns( algorithmType, optimizationRuns );
            optimal = singleEvaluation.optimalParams(algorithmType);
            optimalString = Utilities.StructToStringConverter(optimal);
            algorithmName = showSingleRunResults.AlgorithmTypeToStringConverter( algorithmType );
            disp(['algorithm = ' algorithmName ' optimal: ' ...
                   optimalString]);
        end;
    end
    
    %% runOptionsCollection
    
    function R = runOptionsCollection...
            (singleRunFactory, optionsCollection,...
             progressParams  , algorithmType)
        ticID = tic;
        numOptions = length(optionsCollection);
        progressParams.numParametersOptions = numOptions;

        algorithmsToRun = AlgorithmsCollection;
        algorithmsToRun.setRun(algorithmType);
            
        allRuns = [];
        for params_i=1:numOptions
            % Display progress string
            progressParams.params_i = params_i;
            ExperimentRunFactory.displayOptimizationProgress(progressParams);

            clear singleOption;
            singleOption{algorithmType} = optionsCollection(params_i); %#ok<AGROW>

            singleRun = singleRunFactory.run(singleOption, algorithmsToRun );

            allRuns = [allRuns singleRun]; %#ok<AGROW>
        end
        toc(ticID);
        R = allRuns;
    end
    
    %% displayEvaluationProgress
    
    function displayEvaluationProgress(progressParams)
        progressString = ...
        [ 'on experiment '   num2str(progressParams.experiment_i)         ...
         ' out of '          num2str(progressParams.numExperiments)        ...
         '. evaluation '     num2str(progressParams.evaluation_i)         ...
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
         '. evaluation '        num2str(progressParams.evaluation_i)         ...
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