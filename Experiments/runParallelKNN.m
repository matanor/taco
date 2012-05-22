function runParallelKNN(resultsDirectory, codeRoot)
%RUNPARALLELKNN Summary of this function goes here
%   Detailed explanation goes here
    disp('runParallelKNN');
    outputManager = initRunOnOdin(resultsDirectory, codeRoot);
    inputFileFullPath = '/u/matanorb/experiments/timit/trainAndTest.mat';
    K = 10;
    instancesPerJob = 500;
%     maxInstances = 10 * instancesPerJob;
    maxInstances = Inf;
    sparseKnn.calcKnnMain(inputFileFullPath, K, instancesPerJob, ...
                          maxInstances,      outputManager);
end

