classdef ExperimentGraph < GraphBase
    %EXPERIMENTGRAPH Summary of this class goes here
    %   Detailed explanation goes here

properties
    m_w_nn;
    m_w_nn_symetric;
    m_lastUsedK;
    m_savedNumFolds;
end
    
methods
    %% constructor
    
    function this = ExperimentGraph()
        this.m_lastUsedK = 0;
    end
    
    %% loadFromSavedFileName
    
    function loadFromSavedFileName(this)
        loadFromSavedFileName@GraphBase(this);
        this.removeExtraSplitVertices(this.m_savedNumFolds);
    end
    
    %% removeExtraSplitVertices
    
    function removeExtraSplitVertices(this, numFolds)
        numVertices = this.numVertices();
        newNumVertices = numVertices - mod(numVertices, numFolds);
        verticesToRemove = (newNumVertices+1):numVertices;

        this.removeVertices(verticesToRemove);
        this.m_savedNumFolds = numFolds;
    end
    
    %% clearWeights
    
    function clearWeights(this)
        clearWeights@GraphBase(this);
        this.m_w_nn = [];
        this.m_w_nn_symetric = [];
    end
    
    %% createKnn
    
    function createKnn(this, K)
        rebuild = (K ~= this.m_lastUsedK);
        if rebuild
            if isempty(this.m_weights)
                this.loadFromSavedFileName();
            end
            this.doCreateKnn(K);
            this.m_lastUsedK = K;
        end
        if rebuild
            this.makeSymetric();
            this.m_w_nn_symetric = sparse(this.m_w_nn_symetric);
        end 
    end
    
    %% get_NN
    
    function R = get_NN(this)
        R = full(this.m_w_nn);
    end    
    
    %% get_symetricNN
    
    function R = get_symetricNN(this)
        R = full(this.m_w_nn_symetric);
    end
    
    %% get_weights
    
    function R = get_weights(this)
        R = this.m_weights;
        assert( ~isempty(R));
    end
    
    %% doCreateKnn
    
    function doCreateKnn( this, K )
        %KNN Create K nearest neighbour graph
        %   this.m_weights - symetric weights metrix describing the graph.
        %   K - create a K - NN graph.
        %   This will zero all N-K smallest values per each row.

        this.m_w_nn = this.m_weights;
        this.m_weights = [];
        n = this.numVertices();
        for col_i=1:n
            if mod(col_i,100) == 0
                Logger.log(['col_i = ' num2str(col_i)])
            end
            % Sort row <i> in W. Get the indices for the sort.
            [~,j] = sort(this.m_w_nn(:,col_i), 1);
            
            % Get indices for N-K smallest values per row.
            small_nums_indexes = j( 1:(n - K) );
         
            this.m_w_nn( small_nums_indexes,  col_i ) = 0;
        end;
    end
    
    %% makeSymetric
    
    function makeSymetric( this )
        assert(~issparse(this.m_w_nn)); % This will be really slow for sparse matrices.
        this.m_w_nn_symetric = this.m_w_nn;
        this.m_w_nn = [];
        w_size = size(this.m_w_nn_symetric,1);
        for row_i=1:w_size
            for  col_i=1:w_size
                value = this.m_w_nn_symetric(row_i, col_i);
                if ( value ~= 0)
                    sym_value = this.m_w_nn_symetric( col_i, row_i );
                    if (sym_value == 0)
                        this.m_w_nn_symetric( col_i, row_i ) = value;
                    end
                end
            end
        end
    end
    
end

methods (Static)
    
    %% calcPhiRatio
    % calculate the ratio between edges connecting disagreeing enigbhours
    % and all edges.
    % reference "Using the Mutual k-Nearest Neighbor Graphs for
    % Semi-supervised Classification of Natural Language Data"
    % Ozaki, 2011
    
    function calcPhiRatio(weights, correctLabels)
        [rows, cols, values] = find(weights);
        numEdges = length(rows);
        rowLabels    = correctLabels(rows);
        columnLabels = correctLabels(cols);
        disagreeIndices = rowLabels ~= columnLabels;
        disagreeCount  = sum(disagreeIndices);
        disagreeAmount = sum(values(disagreeIndices));
        phiRatio = disagreeCount / numEdges;
        weightedPhiRatio = disagreeAmount / sum(values);
        Logger.log(['calcPhiRatio. ' ...
                    'phiRatio = '           num2str(phiRatio) ...
                    ' weightedPhiRatio = '   num2str(weightedPhiRatio) ...
                    ]);
    end
end % static methods

end

