function result = run_multiple_experiments...
    ( graphFileName     , numExperiments, ...
      constructionParams, algorithmParams)

result = MultipleRuns;
result.numExperiments = numExperiments;

for i=1:numExperiments
    newExpriment = run_single_experiment ...
        (graphFileName, constructionParams, algorithmParams );
    
    result.addRun(newExpriment);
end

end

