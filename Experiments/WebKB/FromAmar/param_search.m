%% global shared parameters
numRunsPerExperiment = 10;
graphFileName = 'C:\technion\theses\Experiments\WebKB\data\From Amar\webkb_amar.mat';
groupName = 'large_beta_symetric';

%% define parameter properties

%K.range = [1,2,5,10,20,50,100,500];
K.range = [5,7,10];
K.name = 'K';
%alpha.range = [0.0001, 0.001, 0.01,0.1,1];
alpha.range = [ 0.1 ];
alpha.name = 'alpha';
%beta.range = [1,10, 100,1000,10000];
beta.range = [10, 100, 10^3, 10^4,10^5, 10^6, 10^7, 10^8];
beta.name = 'beta';
%labeledConfidence.range = [0.01,0.1];
labeledConfidence.range = [0.1];
labeledConfidence.name = 'labeledConfidence';

paramProperties = [K, alpha, beta, labeledConfidence];

%% create parameters structures

params = createParamsVector(paramProperties);
paramStructs = createParamStructs(paramProperties, params);

%%

ticID = tic;
numStructs = length(paramStructs);
allExperiments = [];
for struct_i=1:numStructs
    currentParams = paramStructs(struct_i);
    
    algorithmParams = currentParams.algorithmParams;
    algorithmParams.numIterations = 50;
    
    constructionParams = currentParams.constructionParams;
    constructionParams.numLabeled = 50;
    constructionParams.numInstancesPerClass = 500;

    experiment.result  = run_multiple_experiments...
        ( graphFileName     , numRunsPerExperiment, ...
          constructionParams, algorithmParams );
    experiment.params = currentParams;
    experiment.fileName = graphFileName;
    allExperiments = [ allExperiments; experiment ];
end
toc(ticID);

%% Define which result figures to display
figuresToShow.singleRuns = 0;
figuresToShow.assumulativeLoss = 1;

%% get total number of experiment
numExperiments = length( allExperiments );

%%
resultsDir = 'C:\technion\theses\Experiments\WebKB\results params\';

%% good
% sorted by precentage 100 vs 900: 161 164 171 175 176 177
% experiment id 90 106 97 98 88 89

%% Create result figures per experiment

%experimentRange =[24 88 89 90 97 98 106 193] % good expoeriments from 216
%experiments
%experimentRange =[334 318 333 313 317 306 378 330 317 357 397 354 329 337 305]
experimentRange = 1:numExperiments;

for experimentID = experimentRange 
    singleExperiment = allExperiments(experimentID);
    multipleRuns = singleExperiment.result;
    for run_i=1:multipleRuns.num_runs()
        showSingleRunResults( singleExperiment, ...
                              experimentID, run_i, figuresToShow );
    end
    showMultipleExperimentsResults...
        (singleExperiment , figuresToShow, experimentID );
    experimentFigurePath = ...
        [resultsDir groupName '.experiment.' num2str(experimentID) '.fig'];
    saveas(gcf, experimentFigurePath);
    close(gcf);
end

%% 

paramsOrder.K   = zeros(numExperiments,1);
for experimentID=1:numExperiments
    singleExperiment = allExperiments(experimentID);
    multipleRuns = singleExperiment.result;
    numMistakes.final(experimentID) = ...
        multipleRuns.sorted_by_confidence.accumulative(end);
    numMistakes.after100(experimentID) = ...
        multipleRuns.sorted_by_confidence.accumulative(100);
    numMistakes.after200(experimentID) = ...
        multipleRuns.sorted_by_confidence.accumulative(200);
	numMistakes.after300(experimentID) = ...
        multipleRuns.sorted_by_confidence.accumulative(300);
   	numMistakes.after500(experimentID) = ...
        multipleRuns.sorted_by_confidence.accumulative(500);
    numMistakes.after900(experimentID) = ...
        multipleRuns.sorted_by_confidence.accumulative(900);
    paramsOrder.K(experimentID) =...
        singleExperiment.params.constructionParams.K;
    paramsOrder.alpha(experimentID) =...
        singleExperiment.params.algorithmParams.alpha;
    paramsOrder.beta(experimentID) =...
        singleExperiment.params.algorithmParams.beta;
    paramsOrder.labeledConfidence(experimentID) =...
        singleExperiment.params.algorithmParams.labeledConfidence;
end

paramsOrder.experimentID = 1:numExperiments;

%%
[sorted.K,sortOrder.K]          = sort(paramsOrder.K);
[sorted.alpha,sortOrder.alpha]  = sort(paramsOrder.alpha);
[sorted.beta,sortOrder.beta]    = sort(paramsOrder.beta);
[sorted.labeledConfidence,sortOrder.labeledConfidence] ...
                                = sort(paramsOrder.labeledConfidence);

%% Plot effect of parameters on total number of mistakes

figurePath = [resultsDir groupName '.params.vs.num_mistakes.fig']; 
plotParamsEffect(numMistakes.final, ...
    sorted, sortOrder, 'total #mistakes', figurePath );

%% Plot effect of parameters on total number of mistakes
%  after 100 most confident vertices

figurePath = [resultsDir groupName '.params.vs.num_mistakes.after.100.fig']; 
title = '#mistakes after 100 most confident vertices';
plotParamsEffect(numMistakes.after100, ...
    sorted, sortOrder, title ,figurePath );

%% after 200 most confident vertices
figurePath = [resultsDir groupName '.params.vs.num_mistakes.after.200.fig']; 
title = '#mistakes after 200 most confident vertices';
plotParamsEffect(numMistakes.after200, ...
    sorted, sortOrder, title, figurePath );

%% after 300 most confident vertices
figurePath = [resultsDir groupName '.params.vs.num_mistakes.after.300.fig']; 
title = '#mistakes after 300 most confident vertices';
plotParamsEffect(numMistakes.after300, ...
    sorted, sortOrder, title, figurePath );


%%
figurePath = [resultsDir groupName '.precentage.100_vs_500.fig']; 
plotPrecentageDiff( numMistakes.after100 / 100, ...
                    numMistakes.after500 / 500, ...
                    numMistakes.final, ...
                    paramsOrder, figurePath );
                
%%

figurePath = [resultsDir groupName '.precentage.100_vs_900.fig']; 
plotPrecentageDiff( numMistakes.after100 / 100, ...
                    numMistakes.after900 / 900,...
                    numMistakes.final, ...
                    paramsOrder, figurePath );
                

%% plot according to sorted 
%  num mistakes / 100 vs num mistakes / 500


