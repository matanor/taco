classdef RunMain

methods (Static)
    %% run
    
    function run(outputManager, isOnOdin)

        %% The parameters manager

        paramsManager = ParamsManager(isOnOdin);
        
        Logger.log(['SAVE_ALL_ITERATIONS_IN_RESULT = ' ...
                     num2str(paramsManager.SAVE_ALL_ITERATIONS_IN_RESULT)]);
        Logger.log(['REAL_RANDOMIZATION = ' ...
                     num2str(paramsManager.REAL_RANDOMIZATION)]);
        Logger.log(['USE_MEM_QUEUE = ' ...
                     num2str(paramsManager.USE_MEM_QUEUE)]);

        if paramsManager.REAL_RANDOMIZATION
            rand('twister',sum(100*clock)); %#ok<RAND>
        end

        %% what algorithms we want to run in the simulation
        algorithmsToRun = AlgorithmsCollection;
        algorithmsToRun.setRun(SingleRun.MAD);
        algorithmsToRun.setRun(SingleRun.CSSLMC);
        algorithmsToRun.setRun(SingleRun.CSSLMCF);
        algorithmsToRun.setRun(SingleRun.AM);
        
        %% allocate a multiple runs object per each parameter combination
        %  and run all experiments with all the parameter combinations

        experimentRunFactory = ExperimentRunFactory( paramsManager, outputManager );
        experimentRuns = experimentRunFactory.run( algorithmsToRun );

        %% Define which result figures to display
        outputManager.m_showSingleRuns = 1;
        outputManager.m_showAccumulativeLoss = 0;

        %% save results to file.
        if isOnOdin == 1   
             experimentRuns = RunMain.clearGraphs(experimentRuns);
        end
        saveToFileFullPath = outputManager.createFileNameAtCurrentFolder('experimentRuns.mat');
        save( saveToFileFullPath,'experimentRuns');

        RunMain.plotResults(experimentRuns, outputManager);
    end
    
    %% clearGraphs
    
    function experimentRuns = clearGraphs(experimentRuns)        
        numExperiments = length(experimentRuns);
        experimentRange = 1:numExperiments;

        for experimentID = experimentRange
            experimentRun = experimentRuns(experimentID);
            experimentRun.m_graph.clearWeights();
            numParameterRuns = experimentRun.numParameterRuns();
            for parameter_run_i=1:numParameterRuns
                parameterRun = experimentRun.getParameterRun(parameter_run_i);
                parameterRun.m_graph.clearWeights();
            end
        end
    end
    
    %% plotResults
    
    function plotResults(experimentRuns, outputManager)
        if ParamsManager.ASYNC_RUNS == 0 
            RunMain.plotEvaluationSummary(experimentRuns, outputManager);
        else
        	experimentRuns = RunMain.clearGraphs( experimentRuns );
            fileFullPath = outputManager.createFileNameAtCurrentFolder...
                ('EvaluationSummary.mat');
            save(fileFullPath, 'experimentRuns', 'outputManager');
            job = JobManager.createJob(fileFullPath, 'asyncEvaluationSummary', outputManager);
            JobManager.executeJobs( job );
        end

        plottingJobs = RunMain.plotAllSingleResults...
            (experimentRuns, outputManager);
        JobManager.executeJobs(plottingJobs);
    end
    
    %% plotEvaluationSummary
    
    function plotEvaluationSummary(experimentRuns, outputManager)
        
        numExperiments = length(experimentRuns);
        experimentRange = 1:numExperiments;
        Logger.log('**** Multiple Runs Summary ****');
        
        bigTableOutputFileName = outputManager.createFileNameAtCurrentFolder...
                                                ('BigTableSummary.txt');
        resultsSummary = ResultsSummary;
        for experimentID = experimentRange
            Logger.log(['experiment ID = ' num2str(experimentID) ]);
            experimentRun = experimentRuns(experimentID);
            experimentRunResults = ExperimentRunResult;
            experimentRunResults.create(experimentRun)
            experimentRunResults.set_bigTableOutputFileName(bigTableOutputFileName);
            resultsSummary.add(experimentRunResults);
        end
        resultsSummary.printSummary();
    end
    
    %% plotAllSingleResults
    
    function plottingJobs = plotAllSingleResults...
            (experimentRuns, outputManager)
        
        numExperiments = length(experimentRuns);
        experimentRange = 1:numExperiments;

        Logger.log('**** Single Run Results ****');

        plottingJobs = [];
        
        for experimentID = experimentRange
            Logger.log(['experiment ID = ' num2str(experimentID) ...
                  ' of ' num2str(numExperiments)]);
            experimentRun = experimentRuns(experimentID);
            outputManager.startExperimentRun...
                (experimentID, experimentRun.get_constructionParams());
            
            numParameterRuns = experimentRun.numParameterRuns();
            for parameter_run_i=1:numParameterRuns
                outputManager.startParametersRun(parameter_run_i);
                Logger.log(['parameters run index = ' num2str(parameter_run_i) ...
                      ' of ' num2str(numParameterRuns)]);
                parameterRun = experimentRun.getParameterRun(parameter_run_i);
                for algorithm_i = parameterRun.algorithmsRange()
                    algorithmName = AlgorithmTypeToStringConverter.convert(algorithm_i);
                    Logger.log(['algorithm = ' algorithmName]);
                    jobNames = parameterRun.get_optimizationJobNames_perAlgorithm(algorithm_i);
                    descriptionFormat = ['Optimization.' num2str(parameter_run_i) '.%d.' algorithmName];
                    jobFileFullPath = outputManager.createFileNameAtCurrentFolder...
                        (['PlotOptimization.' num2str(parameter_run_i) '.' algorithmName '.mat']);
                    job = RunMain.runAsync_plotSingleResults...
                        ( jobFileFullPath, jobNames, outputManager, descriptionFormat);
                    plottingJobs = [plottingJobs;job]; %#ok<AGROW>
                end
                optimizationMethods = parameterRun.optimizationMethodsCollection();
                for optimization_method_i=optimizationMethods
                    outputManager.startEvaluationRun(optimization_method_i);
                    
                    optimizationMethodName = OptimizationMethodToStringConverter.convert(optimization_method_i);
                    jobNames = parameterRun.evaluationJobNames_perOptimizationMethod...
                                    (optimization_method_i);
                    descriptionFormat = ['Evaluation.' num2str(parameter_run_i) '.%d' ];
                    jobFileFullPath = outputManager.createFileNameAtCurrentFolder...
                        (['PlotEvaluation.' num2str(parameter_run_i) '.' optimizationMethodName '.mat']);
                    job = RunMain.runAsync_plotSingleResults...
                        ( jobFileFullPath, jobNames, outputManager, descriptionFormat);
                    plottingJobs = [plottingJobs;job]; %#ok<AGROW>
                    
                    outputManager.moveUpOneDirectory();
                end
                outputManager.moveUpOneDirectory();
            end
            outputManager.moveUpOneDirectory();
        end
    end
    
    %% runAsync_plotSingleResults
    
    function job = runAsync_plotSingleResults...
            ( jobFileFullPath, jobNamesCollection, outputManager, format)
        if ParamsManager.ASYNC_RUNS == 0
            RunMain.plotSingleResults(jobNamesCollection, outputManager, format );
            JobManager.signalJobIsFinished( jobFileFullPath );
            job = Job;
            job.fileFullPath = jobFileFullPath;
        else
            save(jobFileFullPath,'jobNamesCollection','outputManager','format');
            job = JobManager.createJob...
                (jobFileFullPath, 'asyncPlotSingleResults', outputManager);
        end
    end
    
    %% plotSingleResults
    
    function plotSingleResults( jobNamesCollection, outputManager, format )
        numJobs = length(jobNamesCollection);
        for job_i=1:numJobs
            jobName = jobNamesCollection{job_i};
            jobRunOutput = JobManager.loadJobOutput(jobName );
            outputManager.m_description = sprintf(format, job_i);
            showSingleRunResults.show( jobRunOutput, outputManager );
        end
    end

end % methods (Static)

end