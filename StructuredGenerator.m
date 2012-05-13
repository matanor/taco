classdef StructuredGenerator
    %STRUCTUREDGENERATOR Summary of this class goes here
    %   Detailed explanation goes here
    
properties
    m_gaussianMean;  % Each column is a mean vector for an output gaussian distribution
    m_gaussianCovariance; % Each column is the main diagonal for an output gaussian distribution
    m_transitions;
    m_prior;
end

methods
    function [output, states] = createSequence(this)
        sequenceLength = 50 + randi(100,1);

        numFeatures = size(this.m_gaussianMean, 2);
        initialState = randp( this.m_prior, 1);
        currentState = initialState;
        states = zeros(sequenceLength, 1);
        output = zeros(sequenceLength, numFeatures);
        for sequence_i=1:sequenceLength
            outputMean        = this.m_gaussianMean      ( currentState, : );
            outptutCovariance = this.m_gaussianCovariance( :, :, currentState );
            currentOutput = mvnrnd(outputMean,outptutCovariance,1);
            states(sequence_i) = currentState;
            output(sequence_i,:) = currentOutput;
            probabilitiesToNextState = this.m_transitions(:, currentState).';
            assert(sum(probabilitiesToNextState) == 1);
            nextState = randp(probabilitiesToNextState, 1);
            currentState = nextState;
        end
    end
    
end % methods

methods (Static)
    function main()
        s = StructuredGenerator;
        s.m_gaussianMean = [0 0;
                            0 0];
        s.m_gaussianCovariance(:,:,1) = [3 1.5;
                                         1.5 1];
        s.m_gaussianCovariance(:,:,2) = [3 -1.5;
                                         -1.5 1];
        s.m_transitions = [ 0.6 0.7 ;
                            0.4 0.3 ];
        s.m_prior = [0.2 0.8];
        %dbstop in StructuredGenerator.m at 53;
        [output states] = s.createSequence();
        outputFolder = 'C:\technion\theses\Experiments\StructureSynthetic\data';
        context = 1;
        
        graph = s.createGraph(states, output, context);
        graphName = [outputFolder '\' graph.name];
        save(graphName, 'graph');
        context = 7;
        graph = s.createGraph(states, output, context);
        graphName = [outputFolder '\' graph.name];
        save(graphName, 'graph');
    end
    
    function graph = createGraph( labels, instances, context )
        graph.labels = labels;
        numInstances    = size(instances, 1);
        numFeatures     = size(instances, 2);
        dummyContext = zeros(1, numFeatures);
        instances_with_context = zeros(numInstances, context * numFeatures );
        for instance_i=1:numInstances
            half_context = (context - 1)/2;
            context_range = (instance_i-half_context):(instance_i+half_context);
            contextPosition = 1:numFeatures;
            for context_i=context_range
                if context_i < 1 || context_i > numInstances
                    contextInstance = dummyContext;
                else
                    contextInstance = instances(context_i, :);
                end
                instances_with_context(instance_i, contextPosition) = contextInstance;
                contextPosition = contextPosition + numFeatures;
            end
        end
        weights = zeros(numInstances, numInstances);
        alpha = 2;
        for instance_i=1:numInstances
            x = instances_with_context(instance_i,:);
            for instance_j=1:numInstances
                y = instances_with_context(instance_j,:);
                weights(instance_i, instance_j) = exp(-sum((x-y).^2) / alpha);
            end
        end
        graph.weights = weights;
        graph.name = ['context_' num2str(context)];
    end
end
    
end

