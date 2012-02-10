classdef RunMain

methods (Static)
    %% run
    
    function run(outputManager, isOnOdin)

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
            ( paramsManager, algorithmsToRun, outputManager );

        %% Define which result figures to display
        outputManager.m_showSingleRuns = 1;
        outputManager.m_showAccumulativeLoss = 0;

        %% save results to file.
        if isOnOdin == 1   
             experimentRuns = RunMain.clearGraphs(experimentRuns);
        end
        saveToFileFullPath = outputManager.createFileNameAtCurrentFolder('experimentRuns.mat');
        save( saveToFileFullPath,'experimentRuns');

        %% Plot results.
        if ParamsManager.ASYNC_RUNS == 0     
           RunMain.plotResults(experimentRuns, outputManager);
        else
           experimentRuns = RunMain.clearGraphs( experimentRuns ); %#ok<NASGU>
           fileFullPath = outputManager.createFileNameAtCurrentFolder('PlotResultsJobInput.mat');
           save(fileFullPath, 'experimentRuns', 'outputManager');
           job = JobManager.scheduleJob(fileFullPath, 'asyncPlotResults', outputManager);
           JobManager.waitForJobs( job );
        end        
    end
    
    %% clearGraphs
    
    function experimentRuns = clearGraphs(experimentRuns)
        
        numExperiments = length(experimentRuns);
        experimentRange = 1:numExperiments;

        for experimentID = experimentRange
            experimentRun = experimentRuns(experimentID);
            experimentRun.m_graph = GraphLoader.clearWeights( experimentRun.m_graph );
            numParameterRuns = experimentRun.numParameterRuns();
            for parameter_run_i=1:numParameterRuns
                parameterRun = experimentRun.getParameterRun(parameter_run_i);
                parameterRun.m_graph = GraphLoader.clearWeights( parameterRun.m_graph );
            end
        end
    end
    
    %% plotResults
    
    function plotResults(experimentRuns, outputManager)
        RunMain.plotAllSingleResults (experimentRuns, outputManager);
        RunMain.plotEvaluationSummary(experimentRuns, outputManager);
    end
    
    %% plotAllSingleResults
    
    function plotAllSingleResults(experimentRuns, outputManager)
        
        numExperiments = length(experimentRuns);
        experimentRange = 1:numExperiments;

        disp('**** Single Run Results ****');

        for experimentID = experimentRange
            disp(['experiment ID = ' num2str(experimentID) ...
                  ' of ' num2str(numExperiments)]);
            experimentRun = experimentRuns(experimentID);
            numParameterRuns = experimentRun.numParameterRuns();
            for parameter_run_i=1:numParameterRuns
                outputManager.startParametersRun(parameter_run_i);
                disp(['parameters run index = ' num2str(parameter_run_i) ...
                      ' of ' num2str(numParameterRuns)]);
                parameterRun = experimentRun.getParameterRun(parameter_run_i);
                for algorithm_i = parameterRun.algorithmsRange()
                    disp(['algorithm = ' AlgorithmTypeToStringConverter.convert(algorithm_i)]);
                    numOptimizationRuns = parameterRun.numOptimizationRuns(algorithm_i);
                    for optimization_run_i=1:numOptimizationRuns
                        disp(['optimization run = ' num2str(optimization_run_i) ...
                              ' of ' num2str(numOptimizationRuns)]);
                        optimizationRunJobName = parameterRun.getOptimizationRunJobName(algorithm_i, optimization_run_i);
                        optimizationRun = JobManager.loadJobOutput(optimizationRunJobName);
                        outputManager.m_description = ...
                            ['Optimization.' num2str(parameter_run_i) '.' num2str(optimization_run_i)];
                        showSingleRunResults.show( optimizationRun, outputManager );
                    end
                end
                numEvaluationRuns = parameterRun.numEvaluationRuns();
                optimizationMethods = parameterRun.optimizationMethodsCollection();
                for optimization_method_i=optimizationMethods
                    outputManager.startEvaluationRun(optimization_method_i);
                    for evaluation_run_i=1:numEvaluationRuns
                        disp(['evaluation run = ' num2str(evaluation_run_i) ...
                               ' of ' num2str(numEvaluationRuns)]);
                        evaluationRunJobName = parameterRun.getEvaluationRunJobName...
                            (optimization_method_i, evaluation_run_i);
                        evaluation_run = JobManager.loadJobOutput(evaluationRunJobName);
                        outputManager.m_description = ...
                            ['Evaluation.' num2str(parameter_run_i) '.' num2str(evaluation_run_i)];
                        showSingleRunResults.show( evaluation_run, outputManager );
                    end
                    outputManager.moveUpOneDirectory();
                end
                outputManager.moveUpOneDirectory();
            end
        end
    end
    
    %% plotEvaluationSummary
    
    function plotEvaluationSummary(experimentRuns, outputManager)
        
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

                optimizationMethods = parameterRun.optimizationMethodsCollection();
                for optimization_method_i=optimizationMethods
                    disp(['optimized by = ' OptimizationMethodToStringConverter.convert(optimization_method_i) ]);
                    allEvaluationRuns = MultipleRuns;
                    numEvaluationRuns = parameterRun.numEvaluationRuns();
                    for evaluation_run_i=1:numEvaluationRuns
                        evaluationRunJobName = ...
                            parameterRun.getEvaluationRunJobName...
                                (optimization_method_i, evaluation_run_i);
                        evaluation_run = JobManager.loadJobOutput(evaluationRunJobName);
                        allEvaluationRuns.addRun(evaluation_run);
                    end
                    showMultipleExperimentsResults.show(allEvaluationRuns, outputManager );
                end
            end
        end
    end

end % methods (Static)

end