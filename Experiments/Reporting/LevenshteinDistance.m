classdef LevenshteinDistance
    %LEVENSHTEINDISTANCE Calculate levenshtein distance using sclite tool.
    
properties (Constant)
    SCLITE_EXEC_FILE = './sclite';
end

methods (Static)
    
    %% testOnDesktop
    
    function testOnDesktop()
        outputPrefix = 'c:\technion\theses\test_levenshtein';
        this.test(outputPrefix);
    end
    
    %% testOnOdin
    
    function testOnOdin()
        outputPrefix = '/u/matanorb/test_levenshtein';
        this.test(outputPrefix);
    end
    
    %% test
    
    function test(outputPrefix)
        ld = LevenshteinDistance;
        prediction = (1:6).';
        correct = [1;2;3;3;5;6;];
        segments = [1 3;4 6];
        ld.calculate(prediction, correct, segments, outputPrefix);
    end
end % (Static)
    
methods (Access = public)
    
    %% calculate
    
    function calculate(this, prediction, correct, segments, outputPrefix)
        referenceFilePath  = this.createReferenceFile (correct,    segments, outputPrefix);
        hypothesisFilePath = this.createHypothesisFile(prediction, segments, outputPrefix);
        this.runSclite(referenceFilePath, hypothesisFilePath, outputPrefix);
    end
    
end % methods (Access = public)

methods (Access = private)
    
    %% runSclite
    
    function runSclite(~, referenceFilePath, hypothesisFilePath, outputPrefix)
        outputFilePath = [outputPrefix '.sclite.out'];
        scliteCommand = [this.SCLITE_EXEC_FILE ...
                            ' -r ' referenceFilePath  ' trn'...
                            ' -h ' hypothesisFilePath ' trn'...
                            ' -i rm -o spk'...
                            ' -n ' outputFilePath];
        Logger.log(['sclite command = "' scliteCommand '"']);
        [status, result] = system(scliteCommand);
        if status ~= 0
            Logger.log(['Error starting sclite. outputPrefix: ' outputPrefix...
                        ' status = ' num2str(status)]);
        end
        Logger.log(result);
    end
    
    %% createReferenceFile
    
    function R = createReferenceFile(this, correct, segments, outputPrefix)
        referenceFilePath = [outputPrefix '.ref'];
        this.writeToTrnFile(referenceFilePath, correct, segments);
        R = referenceFilePath;
    end
    
    %% createHeypothesisFile
    
    function R = createHypothesisFile(this, correct, segments, outputPrefix)
        hypothesisFilePath = [outputPrefix '.hyp'];
        this.writeToTrnFile(hypothesisFilePath, correct, segments);
        R = hypothesisFilePath;
    end
    
    %% writeToTrnFile
    
    function writeToTrnFile(this, fileFullPath, output, segments)
        SEGMENT_START_POSITION = 1;
        SEGMENT_END_POSITION   = 2;
        writeFilePermission = 'w';
        outputFile = fopen(fileFullPath, writeFilePermission );
        numSegments = size(segments, 1);
        for segment_i=1:numSegments
            segmentStart = segments(segment_i, SEGMENT_START_POSITION);
            segmentEnd   = segments(segment_i, SEGMENT_END_POSITION);
            segmentData = output(segmentStart:segmentEnd);
            this.writeSegmentToTrnFile(outputFile, segmentData, segment_i);
        end
        fclose(outputFile);
    end
    
    %% writeSegmentToTrnFile
    
    function writeSegmentToTrnFile( ~, outputFile, data, segment_i)
        data = data .';
        assert( size(data, 1) == 1) ; % must be row vector;
        fprintf(outputFile, [num2str(data) ' (segment_' num2str(segment_i) ')\n']);
    end

end % methods (Access = private)
    
end

