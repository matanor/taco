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

        allRuns = [];
        
        numConstructionStructs = length(constructionParams_allOptions);
        progressParams.numExperiments = numConstructionStructs;
        
        for construction_i=1:numConstructionStructs
            constructionParams = constructionParams_allOptions( construction_i );
            constructionParams.classToLabelMap = classToLabelMap;

            experimentRun = ExperimentRun;
            experimentRun.set_constructionParams( constructionParams );
            experimentRun.constructGraph();

            numEvaluationOptions = length(evaluationParams_allOptions);
            
            progressParams.experiment_i  = construction_i;
            progressParams.numEvaluations = numEvaluationOptions;

            for evaluation_i=1:numEvaluationOptions
                progressParams.evaluation_i = evaluation_i;
                
                singleEvaluation    = experimentRun.createEvaluationRun();
                
                % this will create the training split
                singleEvaluation.createTrunsductionSplit();
                
                evaluationParams = evaluationParams_allOptions(evaluation_i);

                disp('******** Optimizing ********');
                
                clear optimalParams;
                optimalParams{SingleRun.MAD} = ...
                    ExperimentRunFactory.optimizeParameters....
                    ( singleEvaluation,    paramsManager,      progressParams, ...
                      algorithmsToRun,  evaluationParams,   SingleRun.MAD   ); %#ok<AGROW>

                optimalParams{SingleRun.CSSLMC} = ...
                    ExperimentRunFactory.optimizeParameters...
                    ( singleEvaluation,    paramsManager,      progressParams, ...
                      algorithmsToRun,  evaluationParams,   SingleRun.CSSLMC ); %#ok<AGROW>

                optimalParams{SingleRun.CSSLMCF} = ...
                    ExperimentRunFactory.optimizeParameters...
                    ( singleEvaluation,    paramsManager,      progressParams, ...
                      algorithmsToRun,  evaluationParams,   SingleRun.CSSLMCF ); %#ok<AGROW>

                % run evaluations
                
                disp('******** Running Evaluations ********');

                allEvaluationRuns = MultipleRuns;
                for evaluation_run_i=1:evaluationParams.numEvaluationRuns
                    % this will create a test split
                    singleEvaluation.createTrunsductionSplit();
                    singleRunFactory = singleEvaluation.createSingleRunFactory();
                    singleRun = singleRunFactory.run(optimalParams, algorithmsToRun );
                    allEvaluationRuns.addRun(singleRun);
                end
                singleEvaluation.setEvaluationRuns( allEvaluationRuns );
            end
        end
    
    R = allRuns;
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
            
            optimizationRuns = ExperimentRunFactory.runOptionsCollection...
                    (singleRunFactory, optimizationParams_allOptions, ...
                     progressParams  , algorithmType);
                 
            singleEvaluation.setParameterTuningRuns( algorithmType, optimizationRuns );
            optimal = singleEvaluation.optimalParams(algorithmType);
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
            ExperimentRunFactory.displayProgress(progressParams);

            clear singleOption;
            singleOption{algorithmType} = optionsCollection(params_i); %#ok<AGROW>

            singleRun = singleRunFactory.run(singleOption, algorithmsToRun );

            allRuns = [allRuns singleRun]; %#ok<AGROW>
        end
        toc(ticID);
        R = allRuns;
    end
    
    %% displayProgress
    
    function displayProgress(progressParams)
        progressString = ...
        [ 'on experiment '  num2str(progressParams.experiment_i)         ...
         ' out of '         num2str(progressParams.numExperiments)        ...
         '. evaluation '    num2str(progressParams.evaluation_i)         ...
         ' out of '         num2str(progressParams.numEvaluations)       ...
         '. params run '    num2str(progressParams.params_i)             ...
         ' out of '         num2str(progressParams.numParametersOptions) ];

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