classdef DefaultFormatReader < handle

properties (Access=public)
    m_inputFileName;
    m_inputFileID;
    m_instancesSet;
end

properties (Constant)
    EOF = -1;
    READ_ALL_INSTANCES = -2;
end

methods (Static)
    function test(fileName)
        d = DefaultFormatReader(fileName);
        d.init();
        d.read();
        d.close();
    end
end

methods 
    
    %% Constructor
    
    function this =  DefaultFormatReader(fileName)
        this.m_inputFileName = fileName;
        this.m_instancesSet = InstancesSet;
        [~, name, ~]  = fileparts(this.m_inputFileName);        
        this.m_instancesSet.set_name(name);
    end
    
    %% instancesSet
    
    function R = instancesSet(this)
        R = this.m_instancesSet;
    end
    
    %% init
    
    function init(this)
        this.m_inputFileID  = fopen(this.m_inputFileName,'r');
    end
    
    %% close
    
    function close(this)
        fclose(this.m_inputFileID);
    end
    
    %% read 
    
    function read( this, maxInstances )
        finished = 0;
        line_i = 1;
        while ~finished
            line = fgets(this.m_inputFileID);
            if isempty(line) ||  (isnumeric(line) && line == this.EOF)
                finished = 1;
            else
                this.processSingleLine(line, line_i);
                line_i = line_i + 1;
            end
            if ( maxInstances ~= this.READ_ALL_INSTANCES && ...
                 line_i > maxInstances )
                Logger.log(['Read ' num2str(line_i-1) '. requestes '...
                            num2str(maxInstances) '. finished.']);
                finished = 1;
            end
            if mod(line_i,1000) == 0
                Logger.log(['Read ' num2str(line_i) ' lines.']);
            end
        end
    end

    %% processSingleLine
    
    function processSingleLine(this, line, line_i)
        try
            entries = textscan(line,'%s','delimiter',' ');
            entries = entries{1};
            numEntries = numel(entries);
            for entry_i=1:numEntries
                singleEntry = entries{entry_i};
                try
                    this.processEntry(line_i, singleEntry );
                catch innerException
                    Logger.log(['Error in entry ' num2str(entry_i) ]);
                    throw(innerException);
                end
            end
        catch exception
            Logger.log(['Error in line ' num2str(line_i) ]);
            throw(exception);
        end
    end
    
    %% processEntry
    
    function processEntry(this, instance_i, entry)
        parts = textscan(entry,'%s','delimiter',':');
        parts = parts{1};
        entryType = parts{1};
        entryValue = parts{2};
        switch entryType
            case '#label#'
                labelName = entryValue;
                labelNumber = this.m_instancesSet.labelNameToLabelNumber(labelName);
                this.m_instancesSet.setLabelForInstance(instance_i, labelNumber);
            case '#id#'
                % ignore id
            otherwise
                featureName = entryType;
                featureValue = str2double(entryValue);
                featureNumber = this.m_instancesSet.featureNameToFeatureNumber(featureName);
                this.m_instancesSet.addFeatureToInstance...
                    (instance_i, featureNumber, featureValue);
        end
    end
    
end


end

