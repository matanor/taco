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

%%
numExperiments = length( allExperiments );
for experiment_i=1:numExperiments
    singleExperiment = allExperiments(experiment_i);
    showResults( singleExperiment, figuresToShow, experiment_i );
    %close all;
end
