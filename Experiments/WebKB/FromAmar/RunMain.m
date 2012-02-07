classdef RunMain

methods (Static)
    %% run
    
    function run(outputProperties, isOnOdin)

        %% global shared parameters
        %graphFileName = 'C:\technion\theses\Experiments\WebKB\data\Rapid_Miner_Result\webkb_constructed.mat';
        %graphFileName = 'C:\technion\theses\Experiments\WebKB\data\From Amar\webkb_amar.mat';

        %% The parameters manager

        paramsManager = ParamsManager(isOnOdin);

        %% what algorithms we want to run in the simulation
        algorithmsToRun = AlgorithmsCollection;
        algorithmsToRun.setRun(SingleRun.MAD);
        algorithmsToRun.setRun(SingleRun.CSSLMC);
        algorithmsToRun.setRun(SingleRun.CSSLMCF);

        %% allocate a multiple runs object per each parameter combination
        %  and run all experiments with all the parameter combinations

        experimentRuns = ExperimentRunFactory.run...
            ( paramsManager, algorithmsToRun, outputProperties );

        %% Define which result figures to display
        outputProperties.showSingleRuns = 1;
        outputProperties.showAccumulativeLoss = 0;

        %%
%         resultsDir = 'C:\technion\theses\Experiments\WebKB\results\';
        mkdir(outputProperties.resultsDir,outputProperties.folderName);
%         outputProperties.resultDir = resultsDir;
%         outputProperties.folderName = folderName;

        %%
        RunMain.plotAllSingleResults(experimentRuns, outputProperties);
        
        %%
        RunMain.plotEvaluationSummary(experimentRuns, outputProperties);

        save( [ outputProperties.resultsDir outputProperties.folderName ...
                '/experimentRuns'],'experimentRuns');
        
        return ;
        %% get total number of experiment
        numExperiments = length(experimentRuns);
        
        %% 

        paramsOrder.K   = zeros(numExperiments,1);
        for experimentID=1:numExperiments
            multipleRuns = experimentCollection(experimentID);
            numMistakes.final(experimentID) = ...
                multipleRuns.sorted_by_confidence( SingleRun.CSSLMCF ).accumulative(end);
            %numMistakes.after100(experimentID) = ...
            %    multipleRuns.sorted_by_confidence.accumulative(100);
            %numMistakes.after200(experimentID) = ...
            %    multipleRuns.sorted_by_confidence.accumulative(200);
            %numMistakes.after300(experimentID) = ...
            %    multipleRuns.sorted_by_confidence.accumulative(300);
            %numMistakes.after500(experimentID) = ...
            %    multipleRuns.sorted_by_confidence.accumulative(500);
            %numMistakes.after900(experimentID) = ...
            %    multipleRuns.sorted_by_confidence.accumulative(900);
            paramsOrder.K(experimentID) =...
                multipleRuns.constructionParams().K;
            paramsOrder.alpha(experimentID) =...
                multipleRuns.algorithmParams().alpha;
            paramsOrder.beta(experimentID) =...
                multipleRuns.algorithmParams().beta;
            paramsOrder.labeledConfidence(experimentID) =...
                multipleRuns.algorithmParams().labeledConfidence;
        end

        paramsOrder.experimentID = 1:numExperiments;

        %%
        [sorted.K,sortOrder.K]          = sort(paramsOrder.K);
        [sorted.alpha,sortOrder.alpha]  = sort(paramsOrder.alpha);
        [sorted.beta,sortOrder.beta]    = sort(paramsOrder.beta);
        [sorted.labeledConfidence,sortOrder.labeledConfidence] ...
                                        = sort(paramsOrder.labeledConfidence);

        %% Plot effect of parameters on total number of mistakes

        figurePath = [resultsDir folderName '\params.vs.num_mistakes.fig']; 
        plotParamsEffect(numMistakes.final, ...
            sorted, sortOrder, 'total #mistakes', figurePath );

        %% Plot effect of parameters on total number of mistakes
        %  after 100 most confident vertices

        figurePath = [resultsDir folderName '\params.vs.num_mistakes.after.100.fig']; 
        title = '#mistakes after 100 most confident vertices';
        plotParamsEffect(numMistakes.after100, ...
            sorted, sortOrder, title ,figurePath );

        %% after 200 most confident vertices
        figurePath = [resultsDir folderName '\params.vs.num_mistakes.after.200.fig']; 
        title = '#mistakes after 200 most confident vertices';
        plotParamsEffect(numMistakes.after200, ...
            sorted, sortOrder, title, figurePath );

        %% after 300 most confident vertices
        figurePath = [resultsDir folderName '\params.vs.num_mistakes.after.300.fig']; 
        title = '#mistakes after 300 most confident vertices';
        plotParamsEffect(numMistakes.after300, ...
            sorted, sortOrder, title, figurePath );


        %%
        figurePath = [resultsDir folderName '\precentage.100_vs_500.fig']; 
        plotPrecentageDiff( numMistakes.after100 / 100, ...
                            numMistakes.after500 / 500, ...
                            numMistakes.final, ...
                            paramsOrder, figurePath );

        %%

        figurePath = [resultsDir folderName '\precentage.100_vs_900.fig']; 
        plotPrecentageDiff( numMistakes.after100 / 100, ...
                            numMistakes.after900 / 900,...
                            numMistakes.final, ...
                            paramsOrder, figurePath );


        % plot according to sorted 
        %  num mistakes / 100 vs num mistakes / 500
    end
    
    %% plotAllSingleResults
    
    function plotAllSingleResults(experimentRuns, outputProperties)
        
        numExperiments = length(experimentRuns);
        experimentRange = 1:numExperiments;

        disp('**** Single Run Results ****');

        for experimentID = experimentRange
            disp(['experiment ID = ' num2str(experimentID) ...
                  ' of ' num2str(numExperiments)]);
            experimentRun = experimentRuns(experimentID);
            numParameterRuns = experimentRun.numParameterRuns();
            for parameter_run_i=1:numParameterRuns
                disp(['parameters run index = ' num2str(parameter_run_i) ...
                      ' of ' num2str(numParameterRuns)]);
                parameterRun = experimentRun.getParameterRun(parameter_run_i);
                for algorithm_i = parameterRun.algorithmsRange()
                    disp(['algorithm = ' showSingleRunResults.AlgorithmTypeToStringConverter(algorithm_i)]);
                    numOptimizationRuns = parameterRun.numOptimizationRuns(algorithm_i);
                    for optimization_run_i=1:numOptimizationRuns
                        disp(['optimization run = ' num2str(optimization_run_i) ...
                              ' of ' num2str(numOptimizationRuns)]);
                        optimizationRun = parameterRun.getOptimizationRun(algorithm_i, optimization_run_i);
                        outputProperties.description = ...
                            ['Optimization.' num2str(parameter_run_i) '.' num2str(optimization_run_i)];
                        showSingleRunResults.show( optimizationRun, outputProperties );
                    end
                end
                allEvaluationRuns = parameterRun.getEvaluationRun();
                for evaluation_run_i=1:allEvaluationRuns.num_runs()
                    disp(['evaluation run = ' num2str(evaluation_run_i) ...
                           ' of ' num2str(allEvaluationRuns.num_runs())]);
                    evaluation_run = allEvaluationRuns.getRun(evaluation_run_i);
                    outputProperties.description = ...
                        ['Evaluation.' num2str(parameter_run_i) '.' num2str(evaluation_run_i)];
                    showSingleRunResults.show( evaluation_run, outputProperties );
                end
            end
        end
    end
    
    %% plotEvaluationSummary
    
    function plotEvaluationSummary(experimentRuns, outputProperties)
        
        numExperiments = length(experimentRuns);
        experimentRange = 1:numExperiments;
        disp('**** Multiple Runs Summary ****');

        for experimentID = experimentRange
            disp(['experiment ID = ' num2str(experimentID) ]);
            experimentRun = experimentRuns(experimentID);
            numParameterRuns = experimentRun.numParameterRuns();
            for parameter_run_i=1:numParameterRuns
                disp(['parameters run index = ' num2str(parameter_run_i) ]);
                parameterRun = experimentRun.getParameterRun(parameter_run_i);
                
                allEvaluationRuns = parameterRun.getEvaluationRun();
                showMultipleExperimentsResults.show...
                     (allEvaluationRuns, outputProperties );
            end
        end
    end

end % methods (Static)

end