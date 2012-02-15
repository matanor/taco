classdef ExperimentGraph < GraphBase
    %EXPERIMENTGRAPH Summary of this class goes here
    %   Detailed explanation goes here

properties
    m_w_nn;
    m_w_nn_symetric;
    m_lastUsedK;
end
    
methods
    %% constructor
    
    function this = ExperimentGraph()
        this.m_lastUsedK = 0;
    end
    
    %% removeExtraSplitVertices
    
    function removeExtraSplitVertices(this, numFolds)
        numVertices = this.numVertices();
        newNumVertices = numVertices - mod(numVertices, numFolds);
        verticesToRemove = (newNumVertices+1):numVertices;

        this.removeVertices(verticesToRemove);
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
        if isempty(this.m_w_nn) || rebuild
            this.m_w_nn = knn(this.weights(), K);
            rebuild = 1;
        end
        if isempty(this.m_w_nn_symetric) || rebuild
            this.m_w_nn_symetric = makeSymetric(this.m_w_nn);
        end
        this.m_lastUsedK = K;
    end
    
    %% get_NN
    
    function R = get_NN(this)
        R = this.m_w_nn;
    end    
    
    %% get_symetricNN
    
    function R = get_symetricNN(this)
        R = this.m_w_nn_symetric;
    end
    
end
    
end

