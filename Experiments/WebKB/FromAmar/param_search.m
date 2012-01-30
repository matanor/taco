%%
clear classes;
clear all;

%% global shared parameters
numRunsPerExperiment = 5;
graphFileName = 'C:\technion\theses\Experiments\WebKB\data\From Amar\webkb_amar.mat';
folderName = '2012_01_30_5 CSSLMC(and F) Vs MAD after heuristics fix. multiple runs';

%% define parameter properties

%K.range = [1,2,5,10,20,50,100,500];
K.range = [1000];
K.name = 'K';
%alpha.range = [0.0001, 0.001, 0.01,0.1,1];
%alpha.range = [10^(-5), 10^(-4), 0.001, 0.01,  1, 10^2, 10^4 ];
alpha.range = [ 1 ];
alpha.name = 'alpha';
%beta.range = [1,10, 100,1000,10000];
%beta.range = [10, 100, 10^3, 10^4,10^5, 10^6, 10^7, 10^8];
%beta.range = [10^(-5), 10^(-4), 0.001, 0.01, 1, 10^2, 10^4 ];
beta.range = [ 1 ];
beta.name = 'beta';
%labeledConfidence.range = [0.01,0.1];
labeledConfidence.range = [1];
labeledConfidence.name = 'labeledConfidence';
makeSymetric.range = [1];
makeSymetric.name = 'makeSymetric';
%numIterations.range = [5 10 25 50 100];
numIterations.range = [20];
numIterations.name = 'numIterations';
numLabeled.range = [48];
numLabeled.name = 'numLabeled';
numFolds.range = [4];
numFolds.name = 'numFolds';
numInstancesPerClass.range = 0; % 0 means all instances
numInstancesPerClass.name = 'numInstancesPerClass';
useGraphHeuristics.range = [0 1];
useGraphHeuristics.name = 'useGraphHeuristics';

paramProperties.algorithms   = [ alpha, beta, labeledConfidence, ...
                                 makeSymetric, numIterations, useGraphHeuristics];
paramProperties.construction = [ K, numLabeled, numInstancesPerClass, numFolds];

%% create parameters structures

paramStructs.algorithmParams    = ...
    ParamsManager.createAlgorithmParamsStructures(paramProperties.algorithms);
paramStructs.constructionParams  = ...
    ParamsManager.createConstructionParamsStructures(paramProperties.construction);

%% what algorithms we want to run in the simulation
algorithmsToRun = zeros( SingleRun.numAvailableAlgorithms(), 1);
algorithmsToRun(SingleRun.MAD)      = 1;
algorithmsToRun(SingleRun.CSSLMC)   = 1;
algorithmsToRun(SingleRun.CSSLMCF)  = 1;

%% allocate a multiple runs object per each parameter combination
%  and run all experiments with all the parameter combinations

numParamCombinations =  length(paramStructs.algorithmParams) * ...
                        length(paramStructs.constructionParams);

for param_combination_i = 1:numParamCombinations
    experimentCollection(param_combination_i ) = MultipleRuns;
    experimentCollection(param_combination_i ).numExperiments = numRunsPerExperiment;
end

ticID = tic;
for run_i=1:numRunsPerExperiment
    experimentRuns = run_all_params_experiment.run...
        ( graphFileName, paramStructs, run_i, numRunsPerExperiment, algorithmsToRun );
    for param_combination_i=1:numParamCombinations
        singleRun = experimentRuns(param_combination_i);
        experimentCollection(param_combination_i).addRun...
            ( singleRun );
    end
end
toc(ticID);

%% Define which result figures to display
outputProperties.showSingleRuns = 0;
outputProperties.showAccumulativeLoss = 0;

%% get total number of experiment
numExperiments = numParamCombinations;

%%
resultsDir = 'C:\technion\theses\Experiments\WebKB\results\';
mkdir(resultsDir,folderName);
outputProperties.resultDir = resultsDir;
outputProperties.folderName = folderName;

%% good
% sorted by precentage 100 vs 900: 161 164 171 175 176 177
% experiment id 90 106 97 98 88 89

%% Create result figures per experiment

%experimentRange =[24 88 89 90 97 98 106 193] % good expoeriments from 216
%experiments
%experimentRange =[334 318 333 313 317 306 378 330 317 357 397 354 329 337 305]
experimentRange = 1:numExperiments;

for experimentID = experimentRange
    disp(['experiment ID = ' num2str(experimentID) ]);
    multipleRuns = experimentCollection(experimentID);
    for run_i=1:multipleRuns.num_runs()
        showSingleRunResults.show( multipleRuns, ...
                experimentID, run_i, outputProperties );
    end
     showMultipleExperimentsResults.show...
         (multipleRuns, outputProperties, experimentID );
    experimentFigurePath = ...
        [resultsDir folderName '\experiment.' num2str(experimentID) '.fig'];
    saveas(gcf, experimentFigurePath);
    close(gcf);
end

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
                

%% plot according to sorted 
%  num mistakes / 100 vs num mistakes / 500


