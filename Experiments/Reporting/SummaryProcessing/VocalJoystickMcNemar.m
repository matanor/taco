classdef VocalJoystickMcNemar
    %VOCALJOYSTICKMCNEMAR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
methods (Static)
    
    %% run_vj_mcnemar_test
    
    function run_vj_mcnemar_test()
        inputRoot = 'C:/technion/theses/Matlab/Data/McNemar/thesis/';
        dirwalk(inputRoot, @VocalJoystickMcNemar.mcnemar_test); %varargin
    end
    
    %% mcnemar_test
    %  called on each directory containing files to test
    
    function mcnemar_test(directoryPath, ~)
        directoryPath( directoryPath == '\') = '/';
        files = dir(directoryPath);
        if ~FileHelper.hasSubDirs(files)
            Logger.log(['Running on directory ''' directoryPath '''']);
            results = VocalJoystickMcNemar.readResults_tacoVariants...
                (directoryPath, files);
            mcnemar_result = VocalJoystickMcNemar.calc_mcnemar( results );
            Logger.log(['Results for directory ''' directoryPath '''']);
            t = [];
            for result_i=1:max(results.range)
                name_i = CSSLBase.variantName(result_i);
                t = [t ' ' name_i]; %#ok<AGROW>
            end
            Logger.log(t);
            disp(mcnemar_result.p_value);
            disp(mcnemar_result.betterSystem);
        end
    end
    
    %% calc_mcnemar
    
    function R = calc_mcnemar( results )
        for results_i = results.range
            for results_j = results.range
                if results_i <  results_j 
                    algorithmType = SingleRun.CSSLMC;
                    p1 = results.algorithmResults{results_i}.testSet_prediciton(algorithmType);
                    p2 = results.algorithmResults{results_j}.testSet_prediciton(algorithmType);
                    correct = results.algorithmResults{results_i}.testSetCorrectLabels;
                    mcnemar_result = McNemar.calculate( correct, p1, p2 );
                    R.p_value{results_i, results_j} = mcnemar_result.p_value; %#ok<AGROW>
                    if mcnemar_result.betterSystem == 'A'
                        R.betterSystem{results_i, results_j} = results_i; %#ok<AGROW>
                    elseif mcnemar_result.betterSystem == 'B'
                        R.betterSystem{results_i, results_j} = results_j; %#ok<AGROW>
                    else
                        R.betterSystem{results_i, results_j} = 0; %#ok<AGROW>
                    end
                end
            end
        end
    end
    
    %% readResults_tacoVariants
    
    function R = readResults_tacoVariants(directoryPath, files)
        numFiles = length(files);
        objectivesRange = [];
        for file_i=1:numFiles
            fileName = files(file_i).name;
            if fileName(1) ~= '.' 
                fileData = load( [directoryPath '/' fileName] );
                algorithmType = SingleRun.CSSLMC;
                algorithmOutput = fileData.jobOutput.getAlgorithmResults(algorithmType);
                objectiveType = algorithmOutput.m_params.csslObjectiveType;
                algorithmResults{objectiveType} = fileData.jobOutput; %#ok<AGROW>
                objectivesRange = [objectivesRange objectiveType]; %#ok<AGROW>
            end
        end
        R.algorithmResults = algorithmResults;
        R.range = objectivesRange;
    end
        
    %% organize_vj_data_for_mcnemar_test
    %  organize data from VJ experiments into folders,
    %  such that each folders contains results that should be compared
    %  using McNemars test
    
    function organize_vj_data_for_mcnemar_test()
        inputRoot = 'c:/technion/theses/experiments/results/';
        outputDir = 'C:/technion/theses/Matlab/Data/McNemar/thesis/';
        FileHelper.removeDirectoryAndContents([outputDir 'VJ/']);

        %%% 2013_01_30_02 %%%
        
        resultDir = '2013_01_30_02_vj_under_1_percent_taco_variants/';
        
        experimentMapping = ...
            { { 'Experiment_run_1_trainAndDev.instances.v8.w7.k_10.lihi_0_01/',...
                'VJ/VJ-8-7/0_01/', 1 },...
              { 'Experiment_run_2_trainAndDev.instances.v8.w7.k_10.lihi_0_1/',...
                'VJ/VJ-8-7/0_10/', 2 } };  
        
        inputDir = [inputRoot resultDir];
        parameterRunRange = 1:3;
        VJGenerator.copyExperimentRuns(inputDir, outputDir,...
                                       experimentMapping, parameterRunRange);
                                   
        %%% 2013_01_31_01 %%%
        
        experimentMapping{end+1} = ...
            { 'Experiment_run_3_trainAndDev.instances.v8.w7.k_10.lihi_1/',...
                'VJ/VJ-8-7/1/', 3 };
        experimentMapping{end+1} = ...
            { 'Experiment_run_4_trainAndDev.instances.v8.w7.k_10.lihi_10/',...
                'VJ/VJ-8-7/10/', 4 };
        experimentMapping{end+1} = ...
            { 'Experiment_run_5_trainAndDev.instances.v8.w7.k_10.lihi_20/',...
                'VJ/VJ-8-7/20/', 5 };
            
        resultDir = '2013_01_31_01_vj_all_percent_taco_variant_3/'; 
        
        inputDir = [inputRoot resultDir];
        parameterRunRange = 1;
        VJGenerator.copyExperimentRuns(inputDir, outputDir,...
                                       experimentMapping, parameterRunRange);
        
        %%% 2013_02_02_01 %%%
        
        resultDir = '2013_02_02_01_vj_all_dataset_one_percent_variant_3/';
        inputDir = [inputRoot resultDir];
        
        experimentMappingOnePercent = ...
            { { 'Experiment_run_1_trainAndDev.instances.v4.w1.k_10.lihi_1/',...
                'VJ/VJ-4-1/1/', 1 },...
              { 'Experiment_run_2_trainAndDev.instances.v4.w7.k_10.lihi_1/',...
                'VJ/VJ-4-7/1/', 2 },...
              { 'Experiment_run_3_trainAndDev.instances.v8.w1.k_10.lihi_1/',...
                'VJ/VJ-8-1/1/', 3 } };
        VJGenerator.copyExperimentRuns(inputDir, outputDir,...
                                       experimentMappingOnePercent, parameterRunRange);   
                               
        %%% 2012_11_29_01 %%%
        
        resultDir = '2012_11_29_01_VJ_v8_w7_TACO_objectives/';
        inputDir = [inputRoot resultDir];
        parameterRunRange_noVariant3 = [1 3 4];
        experimentMapping = ...
            { { 'Experiment_run_1_trainAndDev.instances.v8.w7.k_10.lihi_4263/',...
                'VJ/VJ-8-7/1/', 1 } };
        VJGenerator.copyExperimentRuns(inputDir, outputDir,...
                                       experimentMapping, parameterRunRange_noVariant3);
        %%% 2012_11_29_03 %%%
        
        resultDir = '2012_11_29_03_VJ_v4_w17_v_8_w1_TACO/';
        inputDir = [inputRoot resultDir];
        VJGenerator.copyExperimentRuns(inputDir, outputDir,...
                                       experimentMappingOnePercent, parameterRunRange_noVariant3);    
                             
        %%% 2012_12_04_01 %%%
        
        experimentMapping = ...
            { { 'Experiment_run_1_trainAndDev.instances.v8.w7.k_10.lihi_10/',...
                'VJ/VJ-8-7/10/', 1 },...
              { 'Experiment_run_2_trainAndDev.instances.v8.w7.k_10.lihi_20/',...
                'VJ/VJ-8-7/20/', 2 } };
            
        resultDir = '2012_12_04_01_VJ_v8_w7_10_20_precent_TACO/';
        inputDir = [inputRoot resultDir];

        VJGenerator.copyExperimentRuns(inputDir, outputDir,...
                                       experimentMapping, parameterRunRange_noVariant3);    
    end
    
    %% copyExperimentRuns
    
    function copyExperimentRuns(inputDir, outputDir, ...
                                experimentMapping, parameterRunRange)
        numExperiments = length(experimentMapping);
        for experiment_i=1:numExperiments
            mapping = experimentMapping{experiment_i};
            experimentInputDir = mapping{1};
            experimentOutputDir = mapping{2};
            experiment_ID = mapping{3};
            experimentPath = [inputDir experimentInputDir ];
            outputPath     = [outputDir experimentOutputDir ];
            VJGenerator.copyParameterRuns(experimentPath,experiment_ID,...
                                          outputPath,parameterRunRange)
        end
    end
    
    %% copyParameterRuns
    
    function copyParameterRuns(experimentPath, experiment_ID, outputPath, parameterRunRange)   
        for parameter_run_i=parameterRunRange
            parameterDir = ['Parameters_run_' num2str(parameter_run_i)];
            fileName = ['Evaluation.' num2str(experiment_ID) ...
                        '.' num2str(parameter_run_i) '.1.accuracy.mat.out.mat'];
            
            FileHelper.CopyFileRenameIfExists...
                    ([experimentPath parameterDir '/accuracy/' fileName ], ...
                     [outputPath fileName] );
        end
    end

end
    
end % classdef

