%%
clear classes;
clear all;

%% global shared parameters
numRunsPerExperiment = 1;
%graphFileName = 'C:\technion\theses\Experiments\WebKB\data\Rapid_Miner_Result\webkb_constructed.mat';
%graphFileName = 'C:\technion\theses\Experiments\WebKB\data\From Amar\webkb_amar.mat';
folderName = '2012_02_02_1 refactoring';

%% The parameters manager

paramsManager = paramsManager;

%% what algorithms we want to run in the simulation
algorithmsToRun = AlgorithmsCollection;
algorithmsToRun.setRun(SingleRun.MAD);
% algorithmsToRun.setRun(SingleRun.CSSLMC);
% algorithmsToRun.setRun(SingleRun.CSSLMCF);

%% allocate a multiple runs object per each parameter combination
%  and run all experiments with all the parameter combinations

experimentRuns = ExperimentRunFactory.run( paramsManager, algorithmsToRun );

%% Define which result figures to display
outputProperties.showSingleRuns = 1;
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

disp('**** Single Run Results ****');

for experimentID = experimentRange
    disp(['experiment ID = ' num2str(experimentID) ]);
    multipleRuns = experimentCollection(experimentID);
    for run_i=1:multipleRuns.num_runs()
        showSingleRunResults.show( multipleRuns, ...
                experimentID, run_i, outputProperties );
    end
end

disp('**** Multiple Runs Summary ****');

for experimentID = experimentRange
    disp(['experiment ID = ' num2str(experimentID) ]);
    multipleRuns = experimentCollection(experimentID);
     showMultipleExperimentsResults.show...
         (multipleRuns, outputProperties, experimentID );
    %experimentFigurePath = ...
    %    [resultsDir folderName '\experiment.' num2str(experimentID) '.fig'];
    %saveas(gcf, experimentFigurePath);
    %close(gcf);
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


