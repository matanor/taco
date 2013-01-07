classdef GraphConstructionTest
    
methods (Static)

    %% createDummyGraph
    %  create a dummy sparse graph, with <numInstances> instances and
    %  <K> neighbours per each instance. 
    %  Generated weights are not symmetric, 
    %  each column will contain excatly <K> non zero entries.
    %  Saves the output weights to file in path <outputFileFullPath>.
    %  The output file will containt a graph structure, with a single
    %  field of graph.weights.
    
    function createDummyGraph(outputFileFullPath, numInstances, K)
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
    %  Compare peformance pf several ways to compute (? what)
    
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
    %  Compare peformance of several ways to 
    %  substract the same vector from all columns.
    %  This will occupy the CPU ofr a few minutes. (~5-7)
    
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

end % methods (Static)
    
end



