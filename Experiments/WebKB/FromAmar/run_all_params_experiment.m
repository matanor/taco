classdef run_all_params_experiment < handle
    
methods (Static)
    function R = run( graphFileName, paramStructs, runIndex, numRuns, algorithmsToRun)

        %% define the classes we use

%         classToLabelMap = [ 1  1;
%                             4 -1 ];
                        
        classToLabelMap = [ 1  1;
                            2  2
                            3  3
                            4  4];
              
        %% 
        allConstructionParams   = paramStructs.constructionParams;
        algorithmParamsCollection      = paramStructs.algorithmParams;

        allRuns = [];
        
        numConstructionStructs = length(allConstructionParams);
        for construction_i=1:numConstructionStructs

            constructionParams = allConstructionParams( construction_i );
            constructionParams.fileName = graphFileName;
            constructionParams.classToLabelMap = classToLabelMap;
            graph = run_all_params_experiment.constructGraph( constructionParams );

            %% Run all param options on the SAME graph

            singleRunFactory = SingleRunFactory;
            singleRunFactory.m_labeledVertices      = graph.labeledVertices;
            singleRunFactory.m_correctLabels        = graph.labels;
            singleRunFactory.m_constructionParams   = constructionParams;
            singleRunFactory.m_folds                = graph.folds;
            
            progressParams.runIndex = runIndex;
            progressParams.numRuns = numRuns;
            progressParams.construction_i = construction_i;
            progressParams.numConstructionStructs = numConstructionStructs;
            allRuns = run_all_params_experiment.runAllParams...
                        (singleRunFactory, algorithmParamsCollection, ...
                         graph           , progressParams, ...
                         algorithmsToRun);
        end
    
    R = allRuns;
    end
    
    %% constructGraph
    
    function graph = constructGraph(constructionParams)
        constructionParams.display();
        % extract construction params

        numFolds             = constructionParams.numFolds;
            
        % load the graph

        %[ graph, labeledVertices ] = GraphLoader.load ...
        %    ( graphFileName, classToLabelMap, numLabeled, ...
        %    numInstancesPerClass );
            
        graph = GraphLoader.loadAll( constructionParams.fileName );
            
        numVertices = length(graph.labels);
        newNumVertices = numVertices - mod(numVertices, numFolds);
        verticesToRemove = (newNumVertices+1):numVertices;
            
        graph.labels(verticesToRemove) = [];
        graph.weights(verticesToRemove,:) = [];
        graph.weights(:,verticesToRemove) = [];
            
        graph.folds = GraphLoader.split(graph, numFolds );
            
        trainingSet = graph.folds(1,:);
        graph.labeledVertices  = GraphLoader.selectLabelsUniformly...
                            (   trainingSet, ...
                                graph.labels, ...
                                constructionParams.classToLabelMap, ...
                                constructionParams.numLabeledPerClass() );
        %labeledVertices = GraphLoader.selectLabeled_atLeastOnePerLabel...
        %                    ( folds(1,:), graph.labels, classToLabelMap, numLabeled); 

        % unlabeled instances from train set
        % trainSetUnlabeled = setdiff(folds(1,:), labeledVertices);

        %[graph labeledVertices] = ...
        %    run_all_params_experiment.removeVertices...
        %        ( graph, labeledVertices, trainSetUnlabeled );

        graph.w_nn = knn(graph.weights, constructionParams.K);

        graph.w_nn_symetric = makeSymetric(graph.w_nn);
    end
    
    %% runAllParams
    
    function R = runAllParams...
            (singleRunFactory, algorithmParamsCollection,...
             graph, progressParams, algorithmsToRun)
        % Run all param options on the SAME graph
        ticID = tic;
        numAlgorithmParamsStructs = length(algorithmParamsCollection);
        progressParams.numAlgorithmParamsStructs = numAlgorithmParamsStructs;

        allRuns = [];
        for params_i=1:numAlgorithmParamsStructs
            % Display progress string
            progressParams.params_i = params_i;
            run_all_params_experiment.displayProgress(progressParams);

            algorithmParams = algorithmParamsCollection(params_i);

            if ( algorithmParams.makeSymetric ~= 0)
                singleRunFactory.m_Weights = graph.w_nn_symetric;
            else
                singleRunFactory.m_Weights = graph.w_nn;
            end
            %algorithmParams.classToLabelMap = classToLabelMap;
            singleRun = singleRunFactory.run(algorithmParams, algorithmsToRun );

            allRuns = [allRuns singleRun]; %#ok<AGROW>
        end
        toc(ticID);
        R = allRuns;
    end
    
    function displayProgress(progressParams)
        progressString = ...
        [ 'on run '      num2str(progressParams.runIndex)               ...
         ' out of '      num2str(progressParams.numRuns)                ...
         '. graph '      num2str(progressParams.construction_i)         ...
         ' out of '      num2str(progressParams.numConstructionStructs) ...
         '. params run ' num2str(progressParams.params_i)               ...
         ' out of '      num2str(progressParams.numAlgorithmParamsStructs) ];

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