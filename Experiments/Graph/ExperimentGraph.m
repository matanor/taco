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
    
    %% doCreateKnn
    
    function doCreateKnn( this, K )
        %KNN Create K nearest neighbour graph
        %   this.m_weights - symetric weights metrix describing the graph.
        %   K - create a K - NN graph.
        %   This will zero all N-K smallest values per each row.

        this.m_w_nn = this.m_weights;
        this.m_weights = [];
        n = this.numVertices();
        for row_i=1:n
            % Sort row <i> in W. Get the indices for the sort.
            [~,j] = sort(this.m_w_nn(row_i,:), 2);
            
            % Get indices for N-K smallest values per row.
            small_nums_indexes = j( 1:(n - K) );
         
            this.m_w_nn( row_i,  small_nums_indexes ) = 0;
        end;
    end
    
    %% makeSymetric
    
    function makeSymetric( this )
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
    
end

