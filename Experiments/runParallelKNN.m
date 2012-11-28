function runParallelKNN(resultsDirectory, codeRoot)
%RUNPARALLELKNN Summary of this function goes here
%   Detailed explanation goes here
    disp('runParallelKNN');
    outputManager = initRunOnOdin(resultsDirectory, codeRoot);
    rootDirectoty = '/u/matanorb/experiments/VJ/';
    allInputFiles{1} = [rootDirectoty 'trainAndDev/trainAndDev.instances.v4.w7.mat'];
    allInputFiles{3} = [rootDirectoty 'trainAndTest/trainAndTest.instances.v4.w7.mat'];
    allInputFiles{2} = [rootDirectoty 'trainAndDev/trainAndDev.instances.v8.w1.mat'];
    allInputFiles{4} = [rootDirectoty 'trainAndTest/trainAndTest.instances.v8.w1.mat'];
                     
	num_files = length(allInputFiles);
	for file_i=1:num_files
        inputFileFullPath = allInputFiles{file_i};
        Logger.log(['::runParallelKNN. inputFileFullPath = ''' inputFileFullPath '''']);
        [~, folder, ~] = fileparts(inputFileFullPath);
        Logger.log(['::runParallelKNN. output in subfolder = ''' folder '''']);
        outputManager.stepIntoFolder(folder);
        K = 10;
        instancesPerJob = 500;
    %     maxInstances = 10 * instancesPerJob;
        maxInstances = Inf;
        sparseKnn.calcKnnMain(inputFileFullPath, K, instancesPerJob, ...
                              maxInstances,      outputManager);
        outputManager.moveUpOneDirectory();
    end
end

