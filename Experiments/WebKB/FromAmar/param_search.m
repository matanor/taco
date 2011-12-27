%% global shared parameters
numRunsPerExperiment = 10;
showResultsDuringRun = 0;
graphFileName = 'C:\courses\theses\WebKB\data\From Amar\webkb_amar.mat';

%% define parameter properties

K.range = [1,2,5,10,20,50,100,500];
% K.range = [20];
K.name = 'K';
alpha.range = [0.1,1,10];
alpha.name = 'alpha';
beta.range = [0.1,1,10];
beta.name = 'beta';
labeledConfidence.range = [0.1,1,10];
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

    experiment.result  = ...
        avg_experiment( graphFileName, numRunsPerExperiment, ...
                        constructionParams, algorithmParams, ...
                        showResultsDuringRun);
    experiment.params = currentParams;
    experiment.fileName = graphFileName;
    allExperiments = [ allExperiments; experiment ];
end
toc(ticID);

%% Define which result figures to display
figuresToShow.predictionAndConfidence = 0;
figuresToShow.marginAndConfidence = 0;
figuresToShow.assumulativeLoss = 1;

%% get total number of experiment
numExperiments = length( allExperiments );

%%
resultsDir = 'C:\courses\theses\Experiments\WebKB\results params\';

%%
%for experiment_i=1:numExperiments
for experiment_i=[24 89 97 98 106 193]
    singleExperiment = allExperiments(experiment_i);
    showResults( singleExperiment, figuresToShow, experiment_i );
    experimentFigurePath = ...
        [resultsDir 'experiment.' num2str(experiment_i) '.fig'];
    saveas(gcf, experimentFigurePath);
    close(gcf);
    %close all;
end

%%
numMistakes     = zeros(numExperiments,1);
paramsOrder.K   = zeros(numExperiments,1);
for experiment_i=1:numExperiments
    singleExperiment = allExperiments(experiment_i);
    numMistakes.final(experiment_i) = ...
        singleExperiment.result.sortedAccumulativeLoss(end);
    numMistakes.after100(experiment_i) = ...
        singleExperiment.result.sortedAccumulativeLoss(100);
    numMistakes.after200(experiment_i) = ...
        singleExperiment.result.sortedAccumulativeLoss(200);
	numMistakes.after300(experiment_i) = ...
        singleExperiment.result.sortedAccumulativeLoss(300);
   	numMistakes.after500(experiment_i) = ...
        singleExperiment.result.sortedAccumulativeLoss(500);
    numMistakes.after900(experiment_i) = ...
        singleExperiment.result.sortedAccumulativeLoss(900);
    paramsOrder.K(experiment_i) =...
        singleExperiment.params.constructionParams.K;
    paramsOrder.alpha(experiment_i) =...
        singleExperiment.params.algorithmParams.alpha;
    paramsOrder.beta(experiment_i) =...
        singleExperiment.params.algorithmParams.beta;
    paramsOrder.labeledConfidence(experiment_i) =...
        singleExperiment.params.algorithmParams.labeledConfidence;
end

paramsOrder.experiment_i = 1:numExperiments;

%%
[sorted.K,sortOrder.K]          = sort(paramsOrder.K);
[sorted.alpha,sortOrder.alpha]  = sort(paramsOrder.alpha);
[sorted.beta,sortOrder.beta]    = sort(paramsOrder.beta);
[sorted.labeledConfidence,sortOrder.labeledConfidence] ...
                                = sort(paramsOrder.labeledConfidence);

%% Plot effect of parameters on total number of mistakes

figurePath = [resultsDir 'params.vs.num_mistakes.fig']; 
plotParamsEffect(numMistakes.final, ...
    sorted, sortOrder, 'total #mistakes', figurePath );

%% Plot effect of parameters on total number of mistakes
%  after 100 most confident vertices

figurePath = [resultsDir 'params.vs.num_mistakes.after.100.fig']; 
title = '#mistakes after 100 most confident vertices';
plotParamsEffect(numMistakes.after100, ...
    sorted, sortOrder, title ,figurePath );

%% after 200 most confident vertices
figurePath = [resultsDir 'params.vs.num_mistakes.after.200.fig']; 
title = '#mistakes after 200 most confident vertices';
plotParamsEffect(numMistakes.after200, ...
    sorted, sortOrder, title, figurePath );

%% after 300 most confident vertices
figurePath = [resultsDir 'params.vs.num_mistakes.after.300.fig']; 
title = '#mistakes after 300 most confident vertices';
plotParamsEffect(numMistakes.after300, ...
    sorted, sortOrder, title, figurePath );


%%
figurePath = [resultsDir 'precentage.100_vs_500.fig']; 
plotPrecentageDiff( numMistakes.after100 / 100, ...
                    numMistakes.after500 / 500, ...
                    paramsOrder, figurePath );
                
%%

figurePath = [resultsDir 'precentage.100_vs_900.fig']; 
plotPrecentageDiff( numMistakes.after100 / 100, ...
                    numMistakes.after900 / 900, ...
                    paramsOrder, figurePath );
                

%% plot according to sorted 
%  num mistakes / 100 vs num mistakes / 500


