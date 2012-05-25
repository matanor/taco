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
        minSequenceLength = 1000;
        sequenceLength = minSequenceLength + randi(1000,1);

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
    
    %% saveGraph

    function saveGraph(this, graph)
        outputFolder = 'C:\technion\theses\Experiments\StructureSynthetic\data';
        graphName = [outputFolder '\' graph.name];
        graph.transitionMatrix = this.m_transitions;
        numVertices = length(graph.labels);
        graph.structuredEdges = [(1:(numVertices-1)).' (2:(numVertices)).'];
        save(graphName, 'graph');        
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
        s.m_transitions = [ 0.9 0.1 ;
                            0.1 0.9 ];
        s.m_prior = [0.5 0.5];
        %dbstop in StructuredGenerator.m at 53;
        [output states] = s.createSequence();
        
        class1 = output(states == 1, :);
        class2 = output(states == 2, :);
        hold on;
        scatter(class1(:,1), class1(:,2) );
        scatter(class2(:,1), class2(:,2) );
        hold off;
        
        context = 1;
        graph = s.createGraph(states, output, context);
%         s.saveGraph( graph );
        
        context = 7;
        graph = s.createGraph(states, output, context);
%         s.saveGraph( graph );
    end
        
    %% createInstancesWithContext
    
    function R = createInstancesWithContext(instances, context)
        numInstances    = size(instances, 1);
        numFeatures     = size(instances, 2);
        dummyContext = zeros(1, numFeatures) * 100; % some dummy value not likely to occur
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
        R = instances_with_context;
    end
    
    %% createGraph
    
    function graph = createGraph( labels, instances, context )
        graph.labels = labels;
        graph.instances = instances;
        numInstances    = size(instances, 1);
        instances_with_context = ...
            StructuredGenerator.createInstancesWithContext(instances, context );
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
    
    %% segmentsToStructuredEdges
    
    function R = segmentsToStructuredEdges(segments)
        lastSeg = segments(end,end);
        structuredEdges = [(1:lastSeg-1).' (2:lastSeg).'];
        segmentsEnd = segments(:,2);
        segmentsEnd = segmentsEnd(1:end-1); % remove last segment end
        structuredEdges(segmentsEnd,:) = [];  % remove edges from segment end to a different segment start
        R = structuredEdges;
    end
    
    %% estimateTransitionMatrix
    
    function R = estimateTransitionMatrix(correctLabels, segments)
        numLabels = length(unique(correctLabels));
        Logger.log(['Number of classes = ' num2str(numLabels)]);
        transitions = zeros(numLabels, numLabels);
        numSegments = size(segments, 1);
        Logger.log(['Number of segments = ' num2str(numSegments)]);
        Logger.log(['Labels sequence length = ' num2str(length(correctLabels))]);
        numTransitions = 0;
        for segment_i=1:numSegments
            segmentStart = segments(segment_i,1);
            segmentEnd   = segments(segment_i,2);
            for frame_i=segmentStart:(segmentEnd-1)
                framePhone      = correctLabels(frame_i);
                nextFramePhone  = correctLabels(frame_i+1);
                transitions(nextFramePhone, framePhone) = ...
                    transitions(nextFramePhone, framePhone) + 1;
                numTransitions = numTransitions +1;
            end
        end
        Logger.log(['Number of transitions = ' num2str(numTransitions)]);
        R = transitions ./ repmat(sum(transitions, 1), numLabels, 1);
    end
    
    %% sampleSegments
    
    function R = sampleSegments(correctLabels, segments, precentToSample)
        numLabels = length(unique(correctLabels));
        minNumSamplesPerLabel = 1;
        numSampledFromEachLabel = zeros(numLabels, 1);
        numSegments = size(segments, 1);
        numFrames = length(correctLabels);
        Logger.log(['numLabels = ' num2str(numLabels)]);
        Logger.log(['numSegments = ' num2str(numSegments)]);
        Logger.log(['numFrames = '   num2str(numFrames)]);
        allSampledSegments = [];
        numLabeledSamples = 0;
        labelsSampleOrder = randperm(numLabels);
        for label_i=labelsSampleOrder
            finished = (numSampledFromEachLabel(label_i) >= minNumSamplesPerLabel);
            while ~finished
                sampledSegment = randi(numSegments, 1, 1);
                if ~ismember(sampledSegment, allSampledSegments)
                    segmentStart = segments(sampledSegment, 1);
                    segmentEnd   = segments(sampledSegment, 2);
                    labelsInSegment = correctLabels(segmentStart:segmentEnd);
                    if ismember(label_i, labelsInSegment)
                        finished = 1;
                        allSampledSegments = [allSampledSegments; sampledSegment]; %#ok<AGROW>
                        Logger.log(['Adding segment ' num2str(sampledSegment)]);
                        numLabelsInSegment = length(labelsInSegment);
                        numLabeledSamples = numLabeledSamples + numLabelsInSegment;
                        for labelInSegment_i=labelsInSegment
                            numSampledFromEachLabel(labelInSegment_i) = ...
                                numSampledFromEachLabel(labelInSegment_i) + 1;
                        end
                    end
                end
            end
        end
        
        finished = numLabeledSamples > precentToSample * numFrames;
        
        while ~finished
            sampledSegment = randi(numSegments, 1, 1);
            if ~ismember(sampledSegment, allSampledSegments)
                segmentStart = segments(sampledSegment, 1);
                segmentEnd   = segments(sampledSegment, 2);
                labelsInSegment = correctLabels(segmentStart:segmentEnd);
                allSampledSegments = [allSampledSegments; sampledSegment]; %#ok<AGROW>
                numLabeledSamples = numLabeledSamples + length(labelsInSegment);
            end
            finished = numLabeledSamples > precentToSample * numFrames;
        end
        
        assert(length(unique(allSampledSegments)) == length(allSampledSegments));
        
        sampledLabels = [];
        for segment_i=allSampledSegments.'
            segmentStart = segments(segment_i, 1);
            segmentEnd   = segments(segment_i, 2);
            sampledLabels = [sampledLabels; (segmentStart:segmentEnd).']; %#ok<AGROW>
        end
        
        R = sampledLabels;
    end
    
end
    
end

