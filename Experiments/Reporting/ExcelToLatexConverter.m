classdef ExcelToLatexConverter < TextReader
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
properties
    m_allResults;
    m_resultMaps;
    m_header;
    m_numResults;
end

methods (Access = public)
    
    function this = ExcelToLatexConverter()
        this.m_allResults = [];
        this.m_numResults = 0;
        this.m_resultMaps = [];
    end
    
    %% convert
    
    function convert(this, fileName)    
        this.set_inputFileName( fileName );
        this.init();
        this.read(this.READ_ALL);
        this.close();
        this.trimHeaders();
        this.createMaps();
        this.trimValues();
        this.createTables();
        this.clearAll();
    end
    
    %% clearAll
    
    function clearAll(this)
        this.m_allResults = [];
        this.m_numResults = 0;
        this.m_resultMaps = [];
        this.m_header = [];
    end
    
    %% createTables
    
    function createTables(this)
        graph.key = 'graph';
        graphNames = {'webkb_constructed', 'reuters_4_topics.tfidf.graph', ...
                      'farmer-d.tfidf.graph', 'kaminski-v.tfidf.graph' };
        graph.shouldMatch = 1;
        balanced.key = 'balanced';
        balanced.value = '0';
        balanced.shouldMatch = 1;
        num_labeled.key = 'num labeled';
        num_labeled.value = '48';
        num_labeled.shouldMatch = 1;
        labeled_init.key = 'labelled init';
        labeled_init.value = '2';
        labeled_init.shouldMatch = 1;
        optimize_by.key = 'optimize_by';
        %optimize_by.value = 'PRBEP';
        optimize_by.value = 'macroACC';
        optimize_by.shouldMatch = 1;
        searchProperties = [balanced num_labeled labeled_init optimize_by];
        
        outputFileName = [this.inputFileName() '.tex'];
        outputFileID = fopen(outputFileName, 'w+');
        this.startTable( outputFileID );
        
        for graph_i = 1:length(graphNames)
            graph.value = graphNames{graph_i};
            this.printOneDataset(outputFileID, graph.value, [graph searchProperties]);
        end
        this.endTable( outputFileID, graph.value, num_labeled.value, ...
                    labeled_init.value, optimize_by.value );
        fclose(outputFileID);
    end
    
    %% startTable
    
    function startTable(~, outputFile)
        fprintf(outputFile, '\\begin{table}\n');
        fprintf(outputFile, '\\centering\n');
        fprintf(outputFile, '\\begin{tabular}{ | c | c | c | c | c | c | }\n');
        fprintf(outputFile, '\\hline\n');
        fprintf(outputFile, '      &        & diag    & full  & AM    & MAD \\\\ \\hline\n');
    end
    
    %% endTable
    
    function endTable(~, outputFile, dataSetName, numLabeled, ...
                           labeledInit, optimizedBy)
        fprintf(outputFile, '\\hline\n');
        fprintf(outputFile, '\\end{tabular}\n');
        caption = ['results ' ...
                   ' using $\numLabeled=' numLabeled '$, '...
                   ' prior init mode ' labeledInit ...
                   ' and optimized by ' optimizedBy ...
                   ];
                   
        fprintf(outputFile, '\\caption{%s}\n', caption);
        fprintf(outputFile, '\\label{tab:table%s}\n',dataSetName );
        fprintf(outputFile, '\\end{table}\n');
    end
    
    %% printOneDataset
    
    function printOneDataset(this, outputFile, dataSetName, searchProperties )

        algorithm.key = 'Algorithm';
        algorithm.shouldMatch = 1;

        heuristics.key = 'heuristics';
        heuristics.value = '0';
        heuristics.shouldMatch = 1;
        
        algorithm.value = CSSLMC.name();
        diag = this.findEntries([searchProperties heuristics algorithm]);
        diag = diag {1};
        
        algorithm.value = CSSLMCF.name();
        full = this.findEntries([searchProperties heuristics algorithm]);
        full = full {1};
        
        algorithm.value = AM.name();
        am = this.findEntries([searchProperties heuristics algorithm]);
        am = am{1};
        
        heuristics.value = '1';
        
        algorithm.value = MAD.name();
        mad = this.findEntries([searchProperties heuristics algorithm]);
        mad = mad{1};
        
        key = 'avg PRBEP';
        fprintf(outputFile, '%s    & PRBEP  & %.2f      & %.2f    & %.2f    & %.2f  \\\\ \\hline\n', ...
                            dataSetName, 100 * str2num(diag(key)), 100 * str2num(full(key))...
                            , 100 * str2num(am(key)), 100 * str2num(mad(key)));
        key = 'avg accuracy';                
        fprintf(outputFile, '      & ACC    & %.2f      & %.2f    & %.2f    & %.2f  \\\\ \\hline\n', ...
                            100 * str2num(diag(key)), 100 * str2num(full(key))...
                            , 100 * str2num(am(key)), 100 * str2num(mad(key)));
        key = 'avg macro accuracy'; 
        fprintf(outputFile, '      & M-ACC  & %.2f      & %.2f    & %.2f    & %.2f  \\\\ \\hline\n', ...
                            100 * str2num(diag(key)), 100 * str2num(full(key))...
                            , 100 * str2num(am(key)), 100 * str2num(mad(key)));
        key = 'avg MRR'; 
        fprintf(outputFile, '      & MRR    & %.2f      & %.2f    & %.2f    & %.2f  \\\\ \\hline\n', ...
                            100 * str2num(diag(key)), 100 * str2num(full(key))...
                            , 100 * str2num(am(key)), 100 * str2num(mad(key)));
        key = 'avg macro MRR'; 
        fprintf(outputFile, '      & M-MRR  & %.2f      & %.2f    & %.2f    & %.2f  \\\\ \\hline\n', ...
                              100 * str2num(diag(key)), 100 * str2num(full(key))...
                            , 100 * str2num(am(key)), 100 * str2num(mad(key)));
    end
    
    %% findEntries
    
    function R = findEntries( this, searchProperties)
        found_i = 0;
        searchKeys     = {searchProperties.key};
        searchValues   = {searchProperties.value};
        shouldMatch    = [searchProperties.shouldMatch];

        for result_i=1:length(this.m_resultMaps)
            map = this.m_resultMaps{result_i};
            for key_i = 1:length(searchKeys)
                key             = searchKeys{key_i};
                expectedValue   = searchValues{key_i};
                isMatch = 1;
                if strcmp(map(key), expectedValue) ~= shouldMatch(key_i)
                    isMatch = 0;
                    break
                end
            end
            if isMatch
                found_i = found_i + 1;
                R{found_i} = map;
            end
        end        
    end
    
    %% createMaps
    
    function createMaps(this)
        for result_i=1:length(this.m_allResults)
            map = containers.Map();
            result = this.m_allResults{result_i};
            numFields = length(result);
            for field_i = 1:numFields
                fieldName = this.m_header{field_i};
                fieldValue = result{field_i};
                map(fieldName) = fieldValue;
            end
            this.m_resultMaps{result_i} = map;
        end
    end
    
    %% trimValues
    
    function trimValues(this)
        trimKeys = { 'avg PRBEP', 'avg accuracy', ...
                     'avg macro accuracy', 'avg MRR', ...
                     'avg macro MRR'};
        for result_i=1:length(this.m_resultMaps)
            map = this.m_resultMaps{result_i};
            for key_i = 1:length(trimKeys)
                key             = trimKeys{key_i};
                map(key)        = this.trim(map(key));
            end
            this.m_resultMaps{result_i} = map;
        end        
    end

    %% trimHeaders
    
    function trimHeaders(this)
        for header_i = 1:length(this.m_header)
            this.m_header{header_i} = this.trim(this.m_header{header_i});
        end
    end
    
    %% trim
    
    function S = trim(~, S)
        trimPosition = find(S == '(');
        if ~isempty(trimPosition)
            S = S(1:(trimPosition-1));
        end
        S = strtrim(S);
    end
    
    %% processSingleLine
    
    function processSingleLine(this, line, line_i) %#ok<INUSD,MANU>
        if this.isHeader(line, line_i)
            this.readHeader(line);
        else
            this.readResult(line);
        end
    end
    
    %% readHeader
    
    function readHeader(this, line)
        this.m_header = textscan(line, '%s', 'delimiter',',');
        this.m_header = this.m_header{1};
    end
    
    %% readResult
    
    function readResult(this, line)
        result = textscan(line, '%s', 'delimiter',',');
        this.m_numResults = this.m_numResults + 1 ;
        this.m_allResults{this.m_numResults} = result{1};
    end
    
    %% isHeader
    
    function R = isHeader(this, line, line_i)
        FIRST_LINE = 1;
        if (line_i == FIRST_LINE)
            R = 1;
        else
            if isempty(this.m_header)
                R = 0;
            else
                firstToken = textscan(line, '%s %*[^\n]','delimiter',',');
                firstToken = firstToken{1};
                R = strcmp(this.m_header{1}, firstToken);
            end
        end
    end
end

methods (Static)
    function run()
        this = ExcelToLatexConverter();
        fileName = ['C:\technion\theses\Experiments\results\' ...
                    '2012_04_10_03_webkb_enron_reuters_no_L2_truns_sets_from_file_48_96\' ...
                    'BigTableSummary.txt'];

        this.convert(fileName);
    end
end
    
end

