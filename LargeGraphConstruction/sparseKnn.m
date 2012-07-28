classdef sparseKnn
methods (Static)
    
    %% calcKnnMain
    
    function calcKnnMain(inputFileFullPath, K, instancesPerJob, ...
                         maxInstances,      outputManager)
        Logger.log(['Loading file ''' inputFileFullPath '''']);
        fileData = load(inputFileFullPath);
        Logger.log('Done');
        inputGraph = fileData.graph;
        numInstances = size(inputGraph.instances, 2);
        numInstancesToCompute = min(numInstances, maxInstances);
        numJobs = ceil(numInstancesToCompute / instancesPerJob);
        job_i_zero_based = 0;
        allJobs = [];
        Logger.log(['numJobs = ' num2str(numJobs) ' numInstances = ' num2str(numInstances)]);
        for job_i=1:numJobs
            firstInstanceForJob = 1 + job_i_zero_based * instancesPerJob;
            lastInstanceForJob = min(numInstances, firstInstanceForJob + instancesPerJob - 1);
            job_i_zero_based = job_i_zero_based + 1;
            instancesRange = firstInstanceForJob:lastInstanceForJob;
            newJob = sparseKnn.scheduleAsyncKNN(inputFileFullPath, instancesRange, K, outputManager);
            jobInfo{job_i}.instancesRange = instancesRange; %#ok<AGROW>
            allJobs = [allJobs; newJob]; %#ok<AGROW>
        end
        jobsOutputFile = outputManager.createFileNameAtCurrentFolder('allJobs.mat');
        save(jobsOutputFile, 'allJobs');
        JobManager.executeJobs( allJobs );
        
        Logger.log('Connecting all results to one graph');
        tic;
        allRowIndices       = [];
        allColumnIndices    = [];
        allValues           = [];
        for job_i=1:numJobs
            Logger.log(['job_i = ' num2str(job_i)]);
            job = allJobs(job_i);
            partialDistances = JobManager.loadJobOutput(job.fileFullPath);
            [rows_indices,column_indices,value] = find(partialDistances);
            allRowIndices    = [allRowIndices;rows_indices]; %#ok<AGROW>
            allColumnIndices = [allColumnIndices; column_indices]; %#ok<AGROW>
            allValues        = [allValues; value]; %#ok<AGROW>
            instancesRange = jobInfo{job_i}.instancesRange;
            Logger.log(['instancesRange = ' num2str(instancesRange(1)) '_' ...
                                            num2str(instancesRange(end))]);
        end
        
        allDistances = sparse(allRowIndices,allColumnIndices, allValues, ...
                            numInstances, numInstances);
        toc;
        
        outputFileFullPath = [inputFileFullPath '.k_' num2str(K) '.mat'];
        graph.name = [inputGraph.name '_K_' num2str(K)];
        %outputGraph
        graph.distances = allDistances; %#ok<STRNU>
        save(outputFileFullPath, 'graph');
    end
    
    %% scheduleAsyncKNN
    
    function job = scheduleAsyncKNN(inputFileFullPath, instancesRange, K,...
                                          outputManager ) %#ok<INUSL,INUSD>
        Logger.log('scheduleAsyncKNN');
        Logger.log(['instancesRange = ' num2str([instancesRange(1) instancesRange(end)])]);
        firstInstance = instancesRange(1);
        fileName = ['KNN_' num2str(firstInstance) '.mat' ];
        fileFullPath = outputManager.createFileNameAtCurrentFolder(fileName);
        if ParamsManager.ASYNC_RUNS == 0
            result = sparseKnn.calcKnnFromInstances( inputFileFullPath, instancesRange, K);
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
    %  Read input file <inputFileFullPath>
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
            assert (nnz(row_distances) == K);
            % Profiling shows this is not the bottleneck
            result( instance_i, :) = row_distances; %#ok<SPRIX>
        end
        toc;
    end
    
    %% calcKnnOnGraph
        
    function weights = calcKnnOnGraph( weights, K )
        %KNN Create K nearest neighbour graph
        %   graph.weights - symetric weights metrix describing the graph.
        %   K - create a K - NN graph.
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
    
    %% makeSymetric
    
    function weights = makeSymetric(weights)
        [rows,cols,values] = find(weights);
        [numRows numCols] = size(weights);
        allRows     = [rows;cols];
        allColumns  = [cols;rows];
        allValues   = [values;values];
        
        indices = [allRows allColumns];
        [uniqueIndices, usedRows,~] = unique(indices, 'rows');
        uniqueValues = allValues(usedRows);
        uniqueRows = uniqueIndices(:,1);
        uniqueCols = uniqueIndices(:,2);
        
        weights = sparse(uniqueRows, uniqueCols, ...
                         uniqueValues, numRows, numCols);
    end
    
    %% testMakeSymetric
    
    function testMakeSymetric()
        A = [1 2 3; 0 0 0; 0 0 0];
        A = sparse(A);
        sym = sparseKnn.makeSymetric(A);
        A_sym = full(sym);
    end
    
    %% createDummy
    
    function createDummy(outputFileFullPath, numInstances, K)
        allRows = [];
        allCols = [];
        allValues = [];
        for instance_i=1:numInstances
            if mod(instance_i,1000) == 0
                Logger.log(['Instance_i = ' num2str(instance_i)]);
            end
            rows = randi(numInstances, K, 1);
            cols = instance_i * ones(K,1);
            values = ones(K,1);
            allRows  = [allRows; rows]; %#ok<AGROW>
            allCols  = [allCols; cols]; %#ok<AGROW>
            allValues = [allValues; values]; %#ok<AGROW>
        end
        graph.weights = sparse(allRows, allCols, allValues, numInstances, numInstances); %#ok<STRNU>
        save(outputFileFullPath, 'graph');
    end

    %% testCalcDistance
    
    function testCalcDistance()
        numInstances = 10;
        d = 5;
        A = rand(d, d);
        B = rand( d, numInstances);
        iter = 100;
        
        c = zeros(numInstances, 1);
        tic
        for i=1:iter
            c = sum((B.' * A).' .* B);
        end
        toc
        disp(c);

        c = zeros(numInstances, 1);
        tic
        for i=1:iter
            for j=1:numInstances
                c(j) = B(:,j).' * A * B(:,j);
            end
        end
        toc
        disp(c);
        
        c = zeros(numInstances, 1);
        tic
        for i=1:iter
            for j=1:numInstances
                x = B(:,j);
                c(j) = x.' * A * x;
            end
        end
        toc
        disp(c);
        
    end
    
    %% testSubstractVectorFromColumns
    
    % this will occupy the CPU ofr a few minutes. (~5-7)
    function testSubstractVectorFromColumns()
        n = 1e6;
        m = 100;
        iter = 100;
        a = rand(1,m);
        b = rand(n,m);

%         c = zeros(size(b));
%         tic
%         for i = 1:iter
%             c(:,1) = b(:,1) - a(1);
%             c(:,2) = b(:,2) - a(2);
%             c(:,3) = b(:,3) - a(3);
%         end
%         toc

        c = zeros(size(b));
        tic
        for i = 1:iter
            for j = 1:m
                c(:,j) = b(:,j) - a(j);
            end
        end
        toc

        c = zeros(size(b));
        tic
        for i = 1:iter
            c = b-repmat(a,size(b,1),1);
        end
        toc

        tic
        for i = 1:iter
            c = bsxfun(@minus,b,a);
        end
        toc

        c = zeros(size(b));
        tic
        for i = 1:iter
            for j = 1:size(b,1)
                c(j,:) = b(j,:) - a;
            end
        end
        toc
    end
end
end
