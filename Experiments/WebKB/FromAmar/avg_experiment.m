function total = avg_experiment...
    ( numExperiments, K, numLabeled,...
      numInstancesPerClass, num_iterations )

numVertices = numInstancesPerClass * 2;
total.accumulativeLoss = zeros(numVertices, 1);
total.sortedConfidence = zeros(numVertices, 1);
total.sortedMargin = zeros(numVertices, 1);
for i=1:numExperiments
    exp = run_webkb_amar(K, numLabeled, ...
        numInstancesPerClass, num_iterations);
    %r = exp.completeResult
    %for i=1:50 figure;scatter( 1:1000, r.mu(:,i) ); end
    
    total.accumulativeLoss =...
        total.accumulativeLoss + exp.accumulativeLoss;
    total.sortedConfidence = ...
        total.sortedConfidence + exp.sortedConfidence;
    total.sortedMargin = ...
        total.sortedMargin + exp.sortedMargin;

%     total.completeResults = ...
%         [ total.completeResults 
end

total.accumulativeLoss = total.accumulativeLoss / numExperiments;
total.sortedConfidence = total.sortedConfidence / numExperiments;
total.sortedMargin = total.sortedMargin / numExperiments;

end

