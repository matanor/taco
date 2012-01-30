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
        allAlgorithmParams      = paramStructs.algorithmParams;

        allRuns = [];
        
        numConstructionStructs = length(allConstructionParams);
        for construction_i=1:numConstructionStructs

            constructionParams = allConstructionParams( construction_i );

            %% extract construction params

            K                    = constructionParams.K;
            numLabeled           = constructionParams.numLabeled;
            numInstancesPerClass = constructionParams.numInstancesPerClass;
            numFolds             = constructionParams.numFolds;
            
            %%  load the graph

            %[ graph, labeledVertices ] = GraphLoader.load ...
            %    ( graphFileName, classToLabelMap, numLabeled, ...
            %    numInstancesPerClass );
            
            graph = GraphLoader.loadAll( graphFileName );
            
            numVertices = length(graph.labels);
            newNumVertices = numVertices - mod(numVertices, numFolds);
            verticesToRemove = (newNumVertices+1):numVertices;
            
            graph.labels(verticesToRemove) = [];
            graph.weights(verticesToRemove,:) = [];
            graph.weights(:,verticesToRemove) = [];
            %numVertices = length(graph.labels);
            
            folds = GraphLoader.split(graph, numFolds );
            numLabeledPerClass = numLabeled / numFolds;
            constructionParams.numLabeledPerClass = numLabeledPerClass;
            
            labeledVertices  = GraphLoader.selectLabelsUniformly...
                                (   folds(1,:),    graph.labels,      classToLabelMap, ...
                                    numLabeledPerClass);
            %labeledVertices = GraphLoader.selectLabeled_atLeastOnePerLabel...
            %                    ( folds(1,:), graph.labels, classToLabelMap, numLabeled); 
            
            % unlabeled instances from train set
            % trainSetUnlabeled = setdiff(folds(1,:), labeledVertices);
            
            %[graph labeledVertices] = ...
            %    run_all_params_experiment.removeVertices...
            %        ( graph, labeledVertices, trainSetUnlabeled );

            w_nn = knn(graph.weights,K);
            correctLabels = graph.labels;

            w_nn_symetric = makeSymetric(w_nn);
            
            %% display parameters
            constructionParamsString = ...
                [' K = '                        num2str(K) ...
                 ' numLabeled = '               num2str(numLabeled) ...
                 ' numInstancesPerClass = '     num2str(numInstancesPerClass) ];

            disp(constructionParamsString );

            %% Run all param options on the SAME graph
            ticID = tic;
            numAlgorithmParamsStructs = length(allAlgorithmParams);

            singleRunFactory = SingleRunFactory;
            singleRunFactory.m_labeledVertices = labeledVertices;
            singleRunFactory.m_correctLabels = correctLabels;

            for params_i=1:numAlgorithmParamsStructs
                %% display progress
                progressString = ...
                [ 'on run '      num2str(runIndex)       ' out of ' num2str(numRuns) ...
                 '. graph '      num2str(construction_i) ' out of ' num2str(numConstructionStructs)...
                 '. params run ' num2str(params_i)       ' out of ' num2str(numAlgorithmParamsStructs) ];

                disp(progressString);
                %%
                
                algorithmParams = allAlgorithmParams(params_i);

                if ( algorithmParams.makeSymetric ~= 0)
                    singleRunFactory.m_Weights = w_nn_symetric;
                else
                    singleRunFactory.m_Weights = w_nn;
                end
                algorithmParams.classToLabelMap = classToLabelMap;
                singleRun = singleRunFactory.run(algorithmParams, algorithmsToRun );
                singleRun.set_constructionParams( constructionParams );
                singleRun.set_folds( folds );

                allRuns = [allRuns singleRun];
            end
            toc(ticID);

        end
    
    R = allRuns;
    end
    
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