classdef VocalJoystickMcNemar
    %VOCALJOYSTICKMCNEMAR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
methods (Static)
    
    %% run_vj_mcnemar_test
    
    function run_vj_mcnemar_test()
        inputRoot = 'C:/technion/theses/Matlab/Data/McNemar/thesis/Variants';
        dirwalk(inputRoot, @VocalJoystickMcNemar.mcnemar_test_variants); %varargin
        
        inputRoot = 'C:/technion/theses/Matlab/Data/McNemar/thesis/baselines';
        dirwalk(inputRoot, @VocalJoystickMcNemar.mcnemar_test_baselines); %varargin
        
        inputRoot = 'C:/technion/theses/Matlab/Data/McNemar/thesis/timit/baselines';
        dirwalk(inputRoot, @VocalJoystickMcNemar.mcnemar_test_baselines); %varargin
    end
    
    %% mcnemar_test_baselines
    %  called on each directory containing files to test
    
    function mcnemar_test_baselines(directoryPath, ~)
        directoryPath( directoryPath == '\') = '/';
        files = dir(directoryPath);
        if ~FileHelper.hasSubDirs(files)
            Logger.log(['Running on directory ''' directoryPath '''']);
            results = VocalJoystickMcNemar.readResults_tacoBaselines...
                (directoryPath, files);
            mcnemar_result = VocalJoystickMcNemar.calc_mcnemar( results );
            Logger.log(['Results for directory ''' directoryPath '''']);
            algorithmNames = AlgorithmProperties.algorithmNames();
            t = [];
            for result_i=1:max(results.range)
                name_i = algorithmNames{result_i};
                t = [t ' ' name_i]; %#ok<AGROW>
            end
            Logger.log(t);
            disp(mcnemar_result.p_value);
            disp(mcnemar_result.betterSystem);
        end
    end
    
    %% readResults_tacoBaselines
    
    function R = readResults_tacoBaselines(directoryPath, files)
        numFiles = length(files);
        algorithmsRange = [SingleRun.CSSLMC SingleRun.MAD SingleRun.QC SingleRun.AM];
        for file_i=1:numFiles
            fileName = files(file_i).name;
            if fileName(1) ~= '.' 
                fileData = load( [directoryPath '/' fileName] );
                for algorithm_i=algorithmsRange
                    if fileData.jobOutput.isResultsAvailable(algorithm_i)
                        algorithmResults{algorithm_i} = fileData.jobOutput; %#ok<AGROW>
                        algorithmType{algorithm_i} = algorithm_i; %#ok<AGROW>
                    end
                end
            end
        end
        R.algorithmResults = algorithmResults;
        R.range            = algorithmsRange;
        R.algorithmType    = algorithmType;
    end
    
    %% mcnemar_test_variants
    %  called on each directory containing files to test
    
    function mcnemar_test_variants(directoryPath, ~)
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
                    result1 = results.algorithmResults{results_i};
                    result2 = results.algorithmResults{results_j};
                    algorithmType1 = results.algorithmType{results_i};
                    algorithmType2 = results.algorithmType{results_j};
                    p1 = result1.testSet_prediciton(algorithmType1);
                    p2 = result2.testSet_prediciton(algorithmType2);
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
                algorithmType{objectiveType} = SingleRun.CSSLMC;
            end
        end
        R.algorithmResults = algorithmResults;
        R.range            = objectivesRange;
        R.algorithmType    = algorithmType;
    end

    %% organize_vj_data_for_mcnemar_test_baslines
    
    function organize_vj_data_for_mcnemar_test_baslines()
        inputRoot = 'c:/technion/theses/experiments/results/';
        outputDir = 'C:/technion/theses/Matlab/Data/McNemar/thesis/baselines/';
        FileHelper.removeDirectoryAndContents([outputDir 'VJ/']);
        
        %%% 2012_11_29_01 %%%
        
        resultDir = '2012_11_29_01_VJ_v8_w7_TACO_objectives/';

        experimentMappingOnePercentVJ_8_7 = ...
            { { 'Experiment_run_1_trainAndDev.instances.v8.w7.k_10.lihi_4263/',...
                'VJ/VJ-8-7/1/', 1 } };  

        inputDir = [inputRoot resultDir];
        parameterRunRange = 1; % 1 is TACO in this experiment
        McNemar.copyExperimentRuns(inputDir, outputDir,...
                   experimentMappingOnePercentVJ_8_7, parameterRunRange);

        %%% 2012_11_29_02 %%%
        
        resultDir = '2012_11_29_02_VJ_v8_w7_OTHERS/';
            
        inputDir = [inputRoot resultDir];
        parameterRunRange = 1;
        McNemar.copyExperimentRuns(inputDir, outputDir,...
                   experimentMappingOnePercentVJ_8_7, parameterRunRange);

        %%% 2012_11_29_03 %%%
        
        resultDir = '2012_11_29_03_VJ_v4_w17_v_8_w1_TACO/';
        
        experimentMappingOnePercent = ...
            { { 'Experiment_run_1_trainAndDev.instances.v4.w1.k_10.lihi_1/',...
                'VJ/VJ-4-1/1/', 1 },...
              { 'Experiment_run_2_trainAndDev.instances.v4.w7.k_10.lihi_1/',...
                'VJ/VJ-4-7/1/', 2 },...
              { 'Experiment_run_3_trainAndDev.instances.v8.w1.k_10.lihi_1/',...
                'VJ/VJ-8-1/1/', 3 } };
            
        inputDir = [inputRoot resultDir];
        parameterRunRange = 1; % 1 is TACO in this experiment
        McNemar.copyExperimentRuns(inputDir, outputDir,...
                                       experimentMappingOnePercent, parameterRunRange);

        %%% 2012_11_29_04 %%%
        
        resultDir = '2012_11_29_04_VJ_v4_w17_v_8_w1_others/';

        inputDir = [inputRoot resultDir];
        parameterRunRange = 1; % 1 is ALL baselines in this experiment
        McNemar.copyExperimentRuns(inputDir, outputDir,...
                                       experimentMappingOnePercent, parameterRunRange);

        %%% 2013_01_30_02 %%%
        
        resultDir = '2013_01_30_02_vj_under_1_percent_taco_variants/';
        
        experimentMappingUnderOnePercent = ...
            { { 'Experiment_run_1_trainAndDev.instances.v8.w7.k_10.lihi_0_01/',...
                'VJ/VJ-8-7/0_01/', 1 },...
              { 'Experiment_run_2_trainAndDev.instances.v8.w7.k_10.lihi_0_1/',...
                'VJ/VJ-8-7/0_10/', 2 } };
        
        inputDir = [inputRoot resultDir];
        parameterRunRange = 1; % 1 is TACO in this experiment
        McNemar.copyExperimentRuns(inputDir, outputDir,...
                                       experimentMappingUnderOnePercent, parameterRunRange);
        
        %%% 2012_12_02_01 %%%
                                   
        resultDir = '2012_12_02_01_VJ_v8_w7_under_1_precent_others/';
        
        inputDir = [inputRoot resultDir];
        parameterRunRange = 1; % 1 is ALL baselines in this experiment
        McNemar.copyExperimentRuns(inputDir, outputDir,...
                                       experimentMappingUnderOnePercent, parameterRunRange);
        
        %%% 2012_12_04_01 %%%
        
        resultDir = '2012_12_04_01_VJ_v8_w7_10_20_precent_TACO/';
        
        experimentMapping_moreOnePercent = ...
            { { 'Experiment_run_1_trainAndDev.instances.v8.w7.k_10.lihi_10/',...
                'VJ/VJ-8-7/10/', 1 },...
              { 'Experiment_run_2_trainAndDev.instances.v8.w7.k_10.lihi_20/',...
                'VJ/VJ-8-7/20/', 2 } };
                
        inputDir = [inputRoot resultDir];
        parameterRunRange = 1; % 1 is TACO in this experiment
        McNemar.copyExperimentRuns(inputDir, outputDir,...
                   experimentMapping_moreOnePercent, parameterRunRange);
        
        %%% 2012_12_05_01 %%%
        
        resultDir = '2012_12_05_01_VJ_v8_w7_10_20_precent_others/';
        
        inputDir = [inputRoot resultDir];
        parameterRunRange = 1; % 1 is ALL baselines in this experiment
        McNemar.copyExperimentRuns(inputDir, outputDir,...
                   experimentMapping_moreOnePercent, parameterRunRange);
    end
    
    %% organize_vj_data_for_mcnemar_test_variants
    %  organize data from VJ experiments into folders,
    %  such that each folders contains results that should be compared
    %  using McNemars test
    
    function organize_vj_data_for_mcnemar_test_variants()
        inputRoot = 'c:/technion/theses/experiments/results/';
        outputDir = 'C:/technion/theses/Matlab/Data/McNemar/thesis/variantas/';
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
        McNemar.copyExperimentRuns(inputDir, outputDir,...
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
        McNemar.copyExperimentRuns(inputDir, outputDir,...
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
        McNemar.copyExperimentRuns(inputDir, outputDir,...
                                       experimentMappingOnePercent, parameterRunRange);   
                               
        %%% 2012_11_29_01 %%%
        
        resultDir = '2012_11_29_01_VJ_v8_w7_TACO_objectives/';
        inputDir = [inputRoot resultDir];
        parameterRunRange_noVariant3 = [1 3 4];
        experimentMapping = ...
            { { 'Experiment_run_1_trainAndDev.instances.v8.w7.k_10.lihi_4263/',...
                'VJ/VJ-8-7/1/', 1 } };
        McNemar.copyExperimentRuns(inputDir, outputDir,...
                                       experimentMapping, parameterRunRange_noVariant3);
        %%% 2012_11_29_03 %%%
        
        resultDir = '2012_11_29_03_VJ_v4_w17_v_8_w1_TACO/';
        inputDir = [inputRoot resultDir];
        McNemar.copyExperimentRuns(inputDir, outputDir,...
                                       experimentMappingOnePercent, parameterRunRange_noVariant3);    
                             
        %%% 2012_12_04_01 %%%
        
        experimentMapping = ...
            { { 'Experiment_run_1_trainAndDev.instances.v8.w7.k_10.lihi_10/',...
                'VJ/VJ-8-7/10/', 1 },...
              { 'Experiment_run_2_trainAndDev.instances.v8.w7.k_10.lihi_20/',...
                'VJ/VJ-8-7/20/', 2 } };
            
        resultDir = '2012_12_04_01_VJ_v8_w7_10_20_precent_TACO/';
        inputDir = [inputRoot resultDir];

        McNemar.copyExperimentRuns(inputDir, outputDir,...
                                       experimentMapping, parameterRunRange_noVariant3);    
    end

end
    
end % classdef

