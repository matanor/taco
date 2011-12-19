function total = avg_experiment...
    ( graphFileName, numExperiments, constructionParams, ...
        algorithmParams, showResults )

numInstancesPerClass = constructionParams.numInstancesPerClass;

numVertices = numInstancesPerClass * 2;
total.sortedAccumulativeLoss = zeros(numVertices, 1);
total.sortedConfidence = zeros(numVertices, 1);
total.sortedMargin = zeros(numVertices, 1);
total.completeResult = [];

for i=1:numExperiments
    exp = run_webkb_amar...
        (graphFileName, constructionParams, ...
        algorithmParams, showResults);
    
    %r = exp.completeResult
    %for i=1:50 figure;scatter( 1:1000, r.mu(:,i) ); end
    
    total.sortedAccumulativeLoss =...
        total.sortedAccumulativeLoss + exp.sortedAccumulativeLoss;
    total.sortedConfidence = ...
        total.sortedConfidence + exp.sortedConfidence;
    total.sortedMargin = ...
        total.sortedMargin + exp.sortedMargin;
    total.completeResult = ...
        [total.completeResult; exp.completeResult];
end

total.sortedAccumulativeLoss = total.sortedAccumulativeLoss / numExperiments;
total.sortedConfidence = total.sortedConfidence / numExperiments;
total.sortedMargin = total.sortedMargin / numExperiments;

end

