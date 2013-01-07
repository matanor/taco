classdef Structured

methods (Static)
    
%% createInstancesWithContext
%  <instances> is a matrix of size (numfeatures X numinstances).
%  from it create instances with structure:
%  instance_with_context(i) = [ ... instance(i-1) instance(i) instance(i+1) ...]
%  Use <segments> to avoid generating context across different segments.
%  <context> - the amount of context to generate around a single instance.
%  should be odd, e.g. 7 will take -+3 from the middle instance

function R = createInstancesWithContext(instances, context, segments)
    numInstances    = size(instances, 2);
    numFeatures     = size(instances, 1);
    dummyContext = zeros(1, numFeatures); % some dummy value
    instances_with_context = zeros(context * numFeatures, numInstances);
    numSegments = size(segments, 1);
    
    Logger.log(['Structured::createInstancesWithContext. numInstances = ' num2str(numInstances)]);
    Logger.log(['Structured::createInstancesWithContext. numFeatures = '  num2str(numFeatures)]);
    Logger.log(['Structured::createInstancesWithContext. numSegments = '  num2str(numSegments)]);
    
    instanceCount = 1;
    for segment_i=1:numSegments
        segmentStart = segments(segment_i,1);
        segmentEnd   = segments(segment_i,2);
        segmentFramesRange = segmentStart:segmentEnd;
        for instance_i=segmentFramesRange
            if mod(instanceCount,100000) == 0
                Logger.log(['Structured::createInstancesWithContext. instanceCount = ' num2str(instanceCount)]);
            end
            half_context = (context - 1)/2;
            context_range = (instance_i-half_context):(instance_i+half_context);
            contextPosition = 1:numFeatures;
            for context_i=context_range
                if context_i < segmentStart || context_i > segmentEnd
                    contextInstance = dummyContext;
                else
                    contextInstance = instances(:, context_i);
                end
                instances_with_context(contextPosition, instance_i) = contextInstance;
                contextPosition = contextPosition + numFeatures;
            end
            instanceCount = instanceCount + 1;
        end
    end
    R = instances_with_context;
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
    Logger.log('estimateTransitionMatrix');
    
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

end % methods (Static)
    
end

