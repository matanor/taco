classdef DistributedKnn
methods (Static)
    
    %% calcKnnMain
    %  main entry point for asyncrounous calculation of K-NN
    %  on a large set of instances.
    %  ***** INPUT *****
    %  <inputFileFullPath> - full path to input instances file.
    %  contents: a graph variable with the fields:
    %                      instances: (features X instances) matrix.
    %                      name:      graph name.
    %  <K>                 - Create <K>-NN graph.
    %  <instancesPerJob>   - number of instances in a single job.
    %  <maxInstances>      - maximum number of instances from the instances
    %                        file to use. for testing.
    %  <outputManager>     - an object managing output folder.
    % ***** OUTPUT ****
    % Output file path is <input file name without extension>'.k_'<K>'.mat'
    % It will contain a 'graph' structure with the fields
    % name      - set to <input graph name>_K_<K>
    % distances - squared distances to K-NN of each node (in rows).
    
    function calcKnnMain(inputFileFullPath, K, instancesPerJob, ...
                         maxInstances,      outputManager)
        Logger.log(['DistributedKnn::calcKnnMain. Loading file ''' inputFileFullPath '''']);
        fileData = load(inputFileFullPath);
        Logger.log('DistributedKnn::calcKnnMain. Done');
        inputGraph = fileData.graph;
        numInstances = size(inputGraph.instances, 2);
        numFeatures  = size(inputGraph.instances, 1);
        numInstancesToCompute = min(numInstances, maxInstances);
        numJobs = ceil(numInstancesToCompute / instancesPerJob);
        job_i_zero_based = 0;
        allJobs = [];
        Logger.log(['DistributedKnn::calcKnnMain.' ...
                    ' numJobs = '       num2str(numJobs) ...
                    ' numInstances = ' num2str(numInstances) ...
                    ' numFeatures = '  num2str(numFeatures)]);
        for job_i=1:numJobs
            firstInstanceForJob = 1 + job_i_zero_based * instancesPerJob;
            lastInstanceForJob = min(numInstances, firstInstanceForJob + instancesPerJob - 1);
            job_i_zero_based = job_i_zero_based + 1;
            instancesRange = firstInstanceForJob:lastInstanceForJob;
            newJob = DistributedKnn.scheduleAsyncKNN(inputFileFullPath, instancesRange, K, outputManager);
            jobInfo{job_i}.instancesRange = instancesRange; %#ok<AGROW>
            allJobs = [allJobs; newJob]; %#ok<AGROW>
        end
        jobsOutputFile = outputManager.createFileNameAtCurrentFolder('allJobs.mat');
        save(jobsOutputFile, 'allJobs');
        JobManager.executeJobs( allJobs );
        
        Logger.log('DistributedKnn::calcKnnMain. Connecting all results to one graph');
        tic;
        allRowIndices       = [];
        allColumnIndices    = [];
        allValues           = [];
        for job_i=1:numJobs
            Logger.log(['DistributedKnn::calcKnnMain. job_i = ' num2str(job_i)]);
            job = allJobs(job_i);
            partialDistances = JobManager.loadJobOutput(job.fileFullPath);
            [rows_indices,column_indices,value] = find(partialDistances);
            allRowIndices    = [allRowIndices;rows_indices]; %#ok<AGROW>
            allColumnIndices = [allColumnIndices; column_indices]; %#ok<AGROW>
            allValues        = [allValues; value]; %#ok<AGROW>
            instancesRange = jobInfo{job_i}.instancesRange;
            Logger.log(['DistributedKnn::calcKnnMain. ' ... 
                        'instancesRange = ' num2str(instancesRange(1)) '_' ...
                                            num2str(instancesRange(end))]);
        end
        
        allDistances = sparse(allRowIndices,allColumnIndices, allValues, ...
                            numInstances, numInstances);
        toc;
        
        [path, name, ~] = fileparts(inputFileFullPath);
        outputFileFullPath = [path name '.k_' num2str(K) '.mat'];
        graph.name = [inputGraph.name '_K_' num2str(K)];
        %outputGraph
        graph.distances = allDistances; %#ok<STRNU>
        Logger.log(['DistributedKnn::calcKnnMain. Saving output to ''' outputFileFullPath '''']);
        save(outputFileFullPath, 'graph');
    end
    
    %% scheduleAsyncKNN
    %  create a single asyncrounous job, calcilating K-NN on some given
    %  range of instances.
    %  ** INPUT **
    %  <inputFileFullPath> - full path to input instances file.
    %  instancesRange
    %  <instancesRange>    - The range of instances to work on.
    %  <K>                 - Create <K>-NN graph.
    %  <outputManager>     - an object managing output folder.
    %  ** Method **
    %  Directly call calcKnnFromInstances() for syncrounous runs.
    %  For asyncrounous runs, create a job that runs asyncCalcKnn().
    %  Then, from the job, asyncCalcKnn() will call calcKnnFromInstances().
    
    function job = scheduleAsyncKNN(inputFileFullPath, instancesRange, K,...
                                          outputManager )
        Logger.log('scheduleAsyncKNN');
        Logger.log(['instancesRange = ' num2str([instancesRange(1) instancesRange(end)])]);
        firstInstance = instancesRange(1);
        fileName = ['KNN_' num2str(firstInstance) '.mat' ];
        fileFullPath = outputManager.createFileNameAtCurrentFolder(fileName);
        if ParamsManager.ASYNC_RUNS == 0
            result = DistributedKnn.calcKnnFromInstances( inputFileFullPath, instancesRange, K);
            JobManager.saveJobOutput( result, fileFullPath);
            JobManager.signalJobIsFinished( fileFullPath );
            job = Job;
            job.fileFullPath = fileFullPath;
        else
            save(fileFullPath,'inputFileFullPath','instancesRange','K');
            job = JobManager.createJob(fileFullPath, 'asyncCalcKnn', outputManager);
        end
    end
    
    %% calcKnnFromInstances
    %  This is the actual K-NN calculation routine, used in both
    %  syncrounous and asyncrounous modes.
    %  Read input file <inputFileFullPath>
    %  contents: a graph variable with the fields:
    %                      instances: features X instances matrix.
    %                      covariance: optional, when isPerformWhitening=1,
    %                      instances are whitened using this covariance.
    %  For every instane in <instancesRange>
    %      calculate distance to all other instances.
    %      Keep only distances to <K>-Nearest Neighbours,
    %      other distances are zeroed.
    
    function result = calcKnnFromInstances(inputFileFullPath, instancesRange, K)
        isPerformWhitening = 0;
        Logger.log(['isPerformWhitening = ' num2str(isPerformWhitening)]);
        Logger.log(['Loading input file full path = ''' inputFileFullPath ''''])
        fileData = load(inputFileFullPath);
        Logger.log('Done');
        
        graph = fileData.graph;
        clear fileData;
        numInstances = size(graph.instances, 2);
        Logger.log(['Instances range = ' num2str(instancesRange(1)) ' ' ...
                    num2str(instancesRange(end)) ...
                    ', K = ' num2str(K)])
        if 1 == isPerformWhitening
            inverse_covariance = inv(graph.covariance);
        end

        tic;
        numRows = length(instancesRange);
        result = sparse(numRows, numInstances);
        for instance_i=instancesRange
            if mod(instance_i, 5) == 0
                Logger.log(['instance_i = ' num2str(instance_i)]);
            end
            current_instance = graph.instances(:, instance_i);
            
            row_diffs = zeros(size(graph.instances));
            % this is faster then repmat, see test below
            for row_j=1:numInstances
                row_diffs(:,row_j) = current_instance - graph.instances(:,row_j);
            end
            
            % This is fastest: (see below) sum((B.' * A).' .* B);
            if 1 == isPerformWhitening
                row_distances = sum((row_diffs.' * inverse_covariance).' .* row_diffs, 1);
            else
                row_distances = sum(row_diffs.^2, 1);
            end
            clear row_diffs;
            assert( row_distances(instance_i) == 0);
%             row_weights(instance_i) = 0;
            
            % Sort row <i> in W. Get the indices for the sort.
            [~,j] = sort(row_distances, 2);
            
            % Get indices for N-K largest values per row.
            % use K+2 because the smallest distance is 0 (from
            % a vertex to itself)
            large_nums_indexes = j( (K+2):end );

            % delete largest distances.
            row_distances( large_nums_indexes ) = 0;
            
%             if createWeights
%                 singleInstanceData = exp(-row_distances);
%                 singleInstanceData(instance_i) = 0;
%             else
%             singleInstanceData = row_distances;
%             end
            row_distances = sparse(row_distances);
            if nnz(row_distances) ~= K;
                Logger.log(['DistributedKnn::calcKnnFromInstances. ' ...
                             ' number of non-zeros under K, possible cause are identical instances '...
                             ' instance_i = ' num2str(instance_i)]);
            end
            assert(nnz(row_distances) <= K );
            % Profiling shows this is not the bottleneck
            result( instance_i, :) = row_distances; %#ok<SPRIX>
        end
        toc;
    end
    
    %% calcKnnOnGraph
        
    function weights = calcKnnOnGraph( weights, K )
        %   Create K nearest neighbour graph.
        %   This is a simple syncrounous version, suitable for small 
        %   graph.
        %
        %   <weights> - Weights matrix describing the graph.
        %               Does not have to be symmetric.
        %               Each row should contain weights to neighbours.
        %   <K>       - create a K - NN graph.
        %   This will zero all N-K smallest values per each row.
        %   Assume that the weights matrix is sparse.

        weights = weights.';    % transpose because the weights are not symetric
        numVertices = size(weights, 1);
        assert( numVertices == size(weights, 2));
        
        allRows     = zeros(numVertices*K,1);
        allColumns  = zeros(numVertices*K,1);
        allValues   = zeros(numVertices*K,1);
        
        insertPosition = 1;
        for col_i=1:numVertices
            if mod(col_i,10000) == 0
                Logger.log(['col_i = ' num2str(col_i)])
            end
            
            [rows,~,values] = find(weights(:,col_i));
            currentK = length(rows);
            
            % Sort column <i> in W. Get the indices for the sort.
            [~, sortOrder] = sort(values);
            
            % Get indices for K largest values per row.
            large_nums_indexes = sortOrder( (currentK - K + 1):end );
         
            selectedRows    = rows(large_nums_indexes);
            selectedColumns = col_i * ones(K, 1);
            selectedValues  = values(large_nums_indexes);
            lastPosition = insertPosition+K-1;
            allRows     (insertPosition:lastPosition) = selectedRows;
            allColumns  (insertPosition:lastPosition) = selectedColumns;
            allValues   (insertPosition:lastPosition) = selectedValues;
            insertPosition = insertPosition + K;
        end;
        
        weights = sparse(allRows, allColumns, allValues, numVertices, numVertices);
    end
    
end
end
