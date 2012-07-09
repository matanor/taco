classdef LevenshteinDistance
    %LEVENSHTEINDISTANCE Calculate levenshtein distance using sclite tool.
    
properties (Constant)    
end

methods (Static)
    
    %% scliteExecScript
    
    function R = scliteExecScript()
        configManager = ConfigManager.get();
        config = configManager.read();
        if config.isOnOdin
            R = '/u/matanorb/code/tools/sctk-2.4.0/sclite.sh';
        else
            R = 'C:\technion\theses\code\tools\sctk-2.4.0\sclite.win.bat';
        end
    end
    
    %% testOnDesktop
    
    function testOnDesktop()
        ConfigManager.initOnDesktop();
        outputPrefix = 'c:\technion\theses\code\tools\sctk-2.4.0\test_data\test_levenshtein';
        LevenshteinDistance.test(outputPrefix);
    end
    
    %% testOnOdin
    
    function testOnOdin()
        outputPrefix = '/u/matanorb/test_levenshtein';
        LevenshteinDistance.test(outputPrefix);
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
    
    function R = calculate(this, prediction, correct, segments, outputPrefix)
        referenceFilePath  = this.createReferenceFile (correct,    segments, outputPrefix);
        hypothesisFilePath = this.createHypothesisFile(prediction, segments, outputPrefix);
        R = this.runSclite(referenceFilePath, hypothesisFilePath, outputPrefix);
    end
    
end % methods (Access = public)

methods (Access = private)
    
    %% updatePathIfRequired
    
    function R = updatePathIfRequired(this, filePath)
        configManager = ConfigManager.get();
        config = configManager.read();
        if config.isOnOdin
            R = filePath;
        else
            R = this.toCygwinFilePath(filePath);
        end
    end
    
    %% toCygwinFilePath
    
    function R = toCygwinFilePath(~, filePath)
        filePath(filePath == '\') = '/';
        R = strrep(filePath, 'c:', '/cygdrive/c');
    end
    
    %% runSclite
    
    function R = runSclite(this, referenceFilePath, hypothesisFilePath, outputPrefix)
        [~, prefixName, ~] = fileparts(outputPrefix);
        outputFilePrefix = [prefixName '.sclite.out'];
        scliteScript = LevenshteinDistance.scliteExecScript();
        referenceFilePath  = this.updatePathIfRequired(referenceFilePath);
        hypothesisFilePath = this.updatePathIfRequired(hypothesisFilePath);
        outputFilePrefix   = this.updatePathIfRequired(outputFilePrefix);
        scliteCommand = [scliteScript ...
                         ' ' referenceFilePath ...
                         ' ' hypothesisFilePath ...
                         ' ' outputFilePrefix];
        Logger.log(['sclite command = "' scliteCommand '"']);
        [status, result] = system(scliteCommand);
        if status ~= 0
            Logger.log(['Error starting sclite. outputPrefix: ' outputPrefix...
                        ' status = ' num2str(status)]);
        end
        Logger.log(result);
        R = 0;
    end
    
    %% createReferenceFile
    
    function R = createReferenceFile(this, correct, segments, outputPrefix)
        referenceFilePath = [outputPrefix '.ref'];
        Logger.log(['createReferenceFile. path = ' referenceFilePath]);
        this.writeToTrnFile(referenceFilePath, correct, segments);
        R = referenceFilePath;
    end
    
    %% createHypothesisFile
    
    function R = createHypothesisFile(this, correct, segments, outputPrefix)
        hypothesisFilePath = [outputPrefix '.hyp'];
        Logger.log(['createHypothesisFile. path = ' hypothesisFilePath]);
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
        fprintf(outputFile, [num2str(data) ' (segment' num2str(segment_i) ')\n']);
    end

end % methods (Access = private)
    
end

