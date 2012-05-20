classdef sparseKnn
methods (Static)
    
    %% calcKnnMain
    
    function calcKnnMain(inputFileFullPath, K, instancesPerJob, ...
                         maxInstances,      outputManager)
        Logger.log(['Loading file ''' inputFileFullPath '''']);
        fileData = load(inputFileFullPath);
        Logger.log('Done');
        graph = fileData.graph;
        numInstances = size(graph.instances, 2);
        numInstances = min(numInstances, maxInstances);
        numJobs = ceil(numInstances / instancesPerJob);
        job_i_zero_based = 0;
        allJobs = [];
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
        
%         allWeights = sparse(numInstances, numInstances);
        Logger.log('Connecting all results to one graph');
        tic;
        allRowIndices       = [];
        allColumnIndices    = [];
        allValues           = [];
        for job_i=1:numJobs
            Logger.log(['job_i = ' num2str(job_i)]);
            job = allJobs(job_i);
            partialWeights = JobManager.loadJobOutput(job.fileFullPath);
            [rows_indices,column_indices,value] = find(partialWeights);
            allRowIndices    = [allRowIndices;rows_indices]; %#ok<AGROW>
            allColumnIndices = [allColumnIndices; column_indices]; %#ok<AGROW>
            allValues        = [allValues; value]; %#ok<AGROW>
            instancesRange = jobInfo{job_i}.instancesRange;
            Logger.log(['instancesRange = ' num2str(instancesRange(1)) '_' ...
                                            num2str(instancesRange(emd))]);
        end
        
        allWeights = sparse(allRowIndices,allColumnIndices, allValues, ...
                            numInstances, numInstances);
        toc;
        
        outputFileFullPath = [inputFileFullPath '.k_' num2str(K) '.mat'];
        outputGraph.name = [graph.name '_K_' num2str(K)];
        %outputGraph
        outputGraph.weights = allWeights; %#ok<STRNU>
        save(outputFileFullPath, 'outputGraph');
    end
    
    %% scheduleAsyncKNN
    
    function job = scheduleAsyncKNN(inputFileFullPath, instancesRange, K,...
                                          outputManager ) %#ok<INUSL,INUSD>
        Logger.log('scheduleAsyncKNN');
        firstInstance = instancesRange(1);
        fileName = ['KNN_' num2str(firstInstance) '.mat' ];
        fileFullPath = outputManager.createFileNameAtCurrentFolder(fileName);
        save(fileFullPath,'inputFileFullPath','instancesRange','K');
        
        job = JobManager.createJob(fileFullPath, 'asyncCalcKnn', outputManager);
    end
    
    %% calcKnn
    
    function result = calcKnn(inputFileFullPath, instancesRange, K)
        Logger.log(['Loading input file full path = ''' inputFileFullPath ''''])
        fileData = load(inputFileFullPath);
        Logger.log('Done');
        
        graph = fileData.graph;
        numInstances = size(graph.instances, 2);
        Logger.log(['Instances range = ' num2str(instancesRange(1)) ' ' ...
                    num2str(instancesRange(end)) ...
                    ', K = ' num2str(K)])
        inverse_covariance = inv(graph.covariance);

        tic;
        numRows = length(instancesRange);
        result = sparse(numRows, numInstances);
        for instance_i=instancesRange
            if mod(instance_i, 50) == 0
                Logger.log(['instance_i = ' num2str(instance_i)]);
            end
            current_instance = graph.instances(:, instance_i);
            
            row_diffs = zeros(size(graph.instances));
            % this is faster then repmat, see test below
            for row_j=1:numInstances
                row_diffs(:,row_j) = current_instance - graph.instances(:,row_j);
            end
            
            % This is fastest: (see below) sum((B.' * A).' .* B);
            row_weights = exp(-sum((row_diffs.' * inverse_covariance).' .* row_diffs, 1));
            assert( row_weights(instance_i) == 1);
            row_weights(instance_i) = 0;
            
            % Sort row <i> in W. Get the indices for the sort.
            [~,j] = sort(row_weights, 2);
            
            % Get indices for N-K smallest values per row.
            n = length(row_weights);
            small_nums_indexes = j( 1:(n - K) );
         
            row_weights( small_nums_indexes ) = 0;
            row_weights = sparse(row_weights);
            % Profiling shows this is not the bottleneck
            result( instance_i, :) = row_weights; %#ok<SPRIX>
        end
        toc;
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
