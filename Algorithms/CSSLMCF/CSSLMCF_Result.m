classdef CSSLMCF_Result < handle
    %CSSLMC_Result Confidence Semi-Supervised Learning Multi-Class Full 
    % Covarianceresult
    %   Detailed explanation goes here
    
    properties (Access = private)
        m_mu;
        m_sigma;
    end % (Access = private)
    
	properties (Access = private)
        BINARY_NUM_LABELS;
        NEGATIVE; 
        POSITIVE; 
    end % (Access = private)
    
    methods (Access = public)
        
        function this = CSSLMCF_Result() % Constructor
            this.BINARY_NUM_LABELS = 2;
            this.NEGATIVE = 1;
            this.POSITIVE = 2;
        end
        
        function set_results(this, resultSource)
            this.m_mu     = resultSource.mu;
            this.m_sigma  = resultSource.sigma;
        end
        
        function add_vertex(this)
            oldNumVertices = this.numVertices;
            newNumVertices = oldNumVertices + 1;
            this.addVertexTo_Mu();
            this.addVertexTo_Sigma(oldNumVertices);
        end
        
        function remove_vertex(this, vertex_i)
            this.m_mu(vertex_i,:,:) = [];
            this.m_sigma (vertex_i,:,:,:) = [];
        end
        
        function r = asText( this, vertex_i, iteration_i)
            mu = this.m_mu( vertex_i, :, iteration_i );
            
           
            sigma(:,:) = this.m_sigma( vertex_i, :,:, iteration_i );
            
            r = sprintf('(%6.4f,%6.4f)\n----\n(%6.4f,%6.4f)\n(%6.4f,%6.4f)', ...
                mu(this.NEGATIVE), mu(this.POSITIVE), ...
                sigma(this.NEGATIVE,this.NEGATIVE), sigma(this.NEGATIVE,this.POSITIVE),...
                sigma(this.POSITIVE,this.NEGATIVE), sigma(this.POSITIVE,this.POSITIVE));
        end
        
        function r = allColors(this, iteration_i)
            r = 0.5 * ( (-1) * this.m_mu(:, this.NEGATIVE, iteration_i) + ...
                               this.m_mu(:, this.POSITIVE, iteration_i));
        end
        
        function r = legend(~)
            r = '(mu (-1),mu (+1))\newline sigma \newline(--,-+)\newline(+-,++)';
        end
        
        function r = numIterations(this)
            r = size( this.m_mu, 3 );
        end
        
        function r = binaryPrediction(this)
            assert( this.numLabels() == (this.BINARY_NUM_LABELS) );
            final_mu = this.m_mu(:,:,end);
            [~,indices] = max(final_mu,[],2);
            final_mu(:,this.NEGATIVE) = -final_mu(:,this.NEGATIVE);
            prediction = zeros(this.numVertices(), 1);
            for vertex_i=1:length(prediction)
                prediction( vertex_i ) = final_mu( vertex_i, indices(vertex_i) );
            end
            r = prediction;
        end
        
        function r = binaryPredictionConfidence(this)
            assert( this.numLabels() == (this.BINARY_NUM_LABELS) );
            final_mu = this.m_mu(:,:,end);
            [~,indices] = max(final_mu,[],2);
            final_sigma = this.m_sigma(:,:,:,end);
            confidence = zeros(this.numVertices(), 1);
            for vertex_i=1:length(confidence)
                confidence( vertex_i ) = ...
                    final_sigma ( vertex_i, indices(vertex_i), indices(vertex_i) );
            end
            r = confidence;
        end
        
    end % (Access = public)
    
    methods (Access = private)
        function r = numVertices(this)
            r = size(this.m_mu,1);
        end
        function r = numLabels(this)
            r = size(this.m_mu,2);
        end
        
        function addVertexTo_Mu(this)
            newMu = zeros(   this.numVertices() + 1, ...
                             this.numLabels(), ...
                             this.numIterations() );
            numIterations   = this.numIterations();
            numLabels       = this.numLabels();
            for iter_i=1:numIterations
                newMu(:,:,iter_i) = [ this.m_mu(:,:,iter_i);
                                      zeros(1, numLabels) ];
            end
            this.m_mu = newMu;
        end
        
        function addVertexTo_Sigma(this, oldNumVertices)
            newSigma = zeros(   oldNumVertices + 1, ...
                                this.numLabels(),...
                                this.numLabels(),...
                                this.numIterations() );
            numIterations   = this.numIterations();
            numLabels       = this.numLabels();
            
            for vertex_i=1:oldNumVertices
                newSigma(vertex_i,:,:,:) = this.m_sigma(vertex_i,:,:,:);
            end
            
            for iter_i=1:numIterations
                newSigma(end,:,:,iter_i) = eye(numLabels);
            end
            
            this.m_sigma = newSigma;
        end
    end
    
end

