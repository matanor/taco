classdef TextReader < handle
    %TEXTREADER Summary of this class goes here
    %   Detailed explanation goes here
    
properties (Access=public)
    m_inputFileName;
    m_inputFileID;
    m_instancesSet;
end

properties (Constant)
    EOF = -1;
    READ_ALL = -2;
end

methods (Static)
    function test()
        d = TextReader();
        fileName = ['C:\technion\theses\Experiments\results\' ...
                    '2012_04_10_03_webkb_enron_reuters_no_L2_truns_sets_from_file_48_96\' ...
                    'BigTableSummary.txt'];
        d.set_inputFileName( fileName );
        d.init();
        d.read(d.READ_ALL);
        d.close();
    end
end

methods (Access = public)
    
    %% inputFileName
    
    function R = inputFileName(this)
        R = this.m_inputFileName;
    end
    
    %% set_inputFileName
    
    function set_inputFileName(this, value)
        this.m_inputFileName = value;
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
    
    function read( this, maxLines )
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
            if ( maxLines ~= this.READ_ALL && ...
                 line_i > maxLines)
                Logger.log(['Read ' num2str(line_i-1) '. requestes '...
                            num2str(maxLines) '. finished.']);
                finished = 1;
            end
            if mod(line_i,100) == 0
                Logger.log(['Read ' num2str(line_i) ' lines.']);
            end
        end
    end
    
    %% internalProcessSingleLine
    
    function internalProcessSingleLine(this, line, line_i) %#ok<MANU>
        try
            processSingleLine(line, line_i);
        catch exception
            Logger.log(['Error in line ' num2str(line_i) ]);
            throw(exception);
        end
    end
    
    %% processSingleLine
    
    function processSingleLine(this, line, line_i) %#ok<INUSD,MANU>
        % hook for derive classes
    end

end
    
end

