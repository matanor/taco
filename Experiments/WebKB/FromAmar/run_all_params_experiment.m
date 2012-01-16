classdef run_all_params_experiment < handle
    
methods (Static)
    function R = run( graphFileName, paramStructs)

        %% define the classes we use

        classToLabelMap = [ 1  1;
                            4 -1 ];
                    
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
            
            %%  load the graph

            [ graph, Ylabeled ] = load_graph ...
                ( graphFileName, classToLabelMap, K, numLabeled, ...
                numInstancesPerClass );

            w_nn          = graph.weights;
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
            singleRunFactory.m_Ylabeled = Ylabeled;
            singleRunFactory.m_correctLabels = correctLabels;

            for params_i=1:numAlgorithmParamsStructs
                
                %% display progress
                progressString = ...
                [ 'graph ' num2str(construction_i) ' out of ' num2str(numConstructionStructs)...
                 '. params run ' num2str(params_i)  ' out of ' num2str(numAlgorithmParamsStructs) ];

                disp(progressString);
                %%
                
                algorithmParams = allAlgorithmParams(params_i);

                if ( algorithmParams.makeSymetric ~= 0)
                    singleRunFactory.m_Weights = w_nn_symetric;
                else
                    singleRunFactory.m_Weights = w_nn;
                end
                algorithmParams.classToLabelMap = classToLabelMap;
                singleRun = singleRunFactory.run(algorithmParams );
                singleRun.set_constructionParams( constructionParams );

                allRuns = [allRuns singleRun];
            end
            toc(ticID);

        end
    
    R = allRuns;
    end

end % methods (Static)

end % classdef