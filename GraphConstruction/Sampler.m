classdef Sampler
    
methods (Static)
    
%% sampleSegmentsForTransductionSet
%  For the case that the train/test splits are constant 
%  e.g. for timit, there are development and test graphs, 
%  each of them has its own partition to train/test nodes.
%  Only sample labeled data.
%  input:
%  <trunsductionSets>: Assumed to already contain the train/test
%  splits. An object of class TransductionSets.
%  <correctLabels>: A vector containing correct labels.
%  <trainSegments>: The labeled frames come from 
%  sampling segments of the training partition. (e.g. sentences
%  for TIMIT speech data )
%  <precentToSample> precent of frames to sample.
%  e.g.: for sampling 2.5% of the data, should pass precentToSample=0.025

function sampleSegmentsForTransductionSet...
        (trunsductionSets, correctLabels, trainSegments, ...
         precentToSample, fileNamePrefix )
%     correctLabels = trainData.phoneids39;
%     segments = trainData.seg;

    sampledForDev = Sampler.sampleSegments(correctLabels,...
        trainSegments, precentToSample);
    Logger.log(['Sampler::sampleSegmentsForTransductionSet. ' ...
                'Sampled ' num2str(length(sampledForDev)) ' examples ' ...
                'for optimization set']);

    sampledForTest = Sampler.sampleSegments(correctLabels,...
        trainSegments, precentToSample);
    Logger.log(['Sampler::sampleSegmentsForTransductionSet. ' ...
                'Sampled ' num2str(length(sampledForTest)) ' examples ' ...
                'for evaluation set']);
            
     trunsductionSets.m_optimizationSets.m_labeled = sampledForDev;
     trunsductionSets.m_evaluationSets.m_labeled = sampledForTest;
     
     fileOutputPath = [fileNamePrefix '_' num2str(precentToSample*100) '.mat'];
     Logger.log(['Sampler::sampleSegmentsForTransductionSet. ' ...
                 'Saving output to ''' fileOutputPath '''']);
     save(fileOutputPath, 'trunsductionSets');
end

%% sampleSegments
%  method: sample segments until at least <minNumSamplesPerLabel> frames 
%  per label are selected, label sample order is random.
%  Then, sample more segments until <precentToSample> frames are selected.
%  e.g.: for sampling 2.5% of the data, should pass precentToSample=0.025

function R = sampleSegments(correctLabels, segments, precentToSample)
    numUniqueLabels = length(unique(correctLabels));
    minNumSamplesPerLabel = 1;
    numSampledFromEachLabel = zeros(numUniqueLabels, 1);
    numSegments = size(segments, 1);
    numFrames = length(correctLabels);
    Logger.log(['numLabels = ' num2str(numUniqueLabels)]);
    Logger.log(['numSegments = ' num2str(numSegments)]);
    Logger.log(['numFrames = '   num2str(numFrames)]);
    allSampledSegments = [];
    numLabeledSamples = 0;
    labelsSampleOrder = randperm(numUniqueLabels);
    Logger.log(['Sampling at least ' num2str(minNumSamplesPerLabel) ' frames per label']);
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

    Logger.log('Adding additional segments');
    
    finished = numLabeledSamples > precentToSample * numFrames;

    while ~finished
        sampledSegment = randi(numSegments, 1, 1);
        if ~ismember(sampledSegment, allSampledSegments)
            segmentStart = segments(sampledSegment, 1);
            segmentEnd   = segments(sampledSegment, 2);
            labelsInSegment = correctLabels(segmentStart:segmentEnd);
            Logger.log(['Adding segment ' num2str(sampledSegment)]);
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

    Logger.log(['Sampled ' num2str(length(allSampledSegments)) ' segments' ...
                ' out of ' num2str(numSegments)]);
    Logger.log(['Sampled ' num2str(length(sampledLabels)) ' labels' ...
                ' out of ' num2str(length(correctLabels))]);
    R = sampledLabels;
end

end % methods (static)

end % classdef