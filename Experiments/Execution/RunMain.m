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

        RunMain.plotResults(experimentRuns, outputManager);
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
        if ParamsManager.ASYNC_RUNS == 0 
            RunMain.plotEvaluationSummary(experimentRuns);
        else
        	experimentRuns = RunMain.clearGraphs( experimentRuns );
            fileFullPath = outputManager.createFileNameAtCurrentFolder...
                ('EvaluationSummary.mat');
            save(fileFullPath, 'experimentRuns', 'outputManager');
            job = JobManager.scheduleJob(fileFullPath, 'asyncEvaluationSummary', outputManager);
            JobManager.waitForJobs( job );
        end

        plottingJobs = RunMain.plotAllSingleResults...
            (experimentRuns, outputManager);
        JobManager.waitForJobs(plottingJobs);
    end
    
    %% plotEvaluationSummary
    
    function plotEvaluationSummary(experimentRuns)
        
        numExperiments = length(experimentRuns);
        experimentRange = 1:numExperiments;
        disp('**** Multiple Runs Summary ****');
        
        resultsSummary = ResultsSummary;
        for experimentID = experimentRange
            disp(['experiment ID = ' num2str(experimentID) ]);
            experimentRun = experimentRuns(experimentID);
            experimentRunResults = ExperimentRunResult;
            experimentRunResults.create(experimentRun)
            resultsSummary.add(experimentRunResults);
        end
        resultsSummary.printSummary();
    end
    
    %% plotAllSingleResults
    
    function plottingJobs = plotAllSingleResults...
            (experimentRuns, outputManager)
        
        numExperiments = length(experimentRuns);
        experimentRange = 1:numExperiments;

        disp('**** Single Run Results ****');

        plottingJobs = [];
        
        for experimentID = experimentRange
            outputManager.startExperimentRun(experimentID);
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
                    algorithmName = AlgorithmTypeToStringConverter.convert(algorithm_i);
                    disp(['algorithm = ' algorithmName]);
                    jobNames = parameterRun.get_optimizationJobNames_perAlgorithm(algorithm_i);
                    descriptionFormat = ['Optimization.' num2str(parameter_run_i) '.%d.' algorithmName];
                    jobFileFullPath = outputManager.createFileNameAtCurrentFolder...
                        (['PlotOptimization.' num2str(parameter_run_i) '.' algorithmName '.mat']);
                    job = RunMain.runAsync_plotSingleResults...
                        ( jobFileFullPath, jobNames, outputManager, descriptionFormat);
                    plottingJobs = [plottingJobs job]; %#ok<AGROW>
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
                    plottingJobs = [plottingJobs job]; %#ok<AGROW>
                    
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
            job = JobManager.scheduleJob...
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