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
        this.createGraphs();
        this.clearAll();
    end
    
    %% clearAll
    
    function clearAll(this)
        this.m_allResults = [];
        this.m_numResults = 0;
        this.m_resultMaps = [];
        this.m_header = [];
    end
    
    %% 
    
    function createGraphs(this)
        graph.key = 'graph';
        graph.value = {'webkb_constructed'};
        graph.shouldMatch = 1;
        
        balanced.key = 'balanced';
        balanced.value = {'0'};
        balanced.shouldMatch = 1;
        
        labeled_init.key = 'labelled init';
        labeled_init.value = {'1'};
        labeled_init.shouldMatch = 1;
        
        searchProperties = [graph balanced labeled_init];
        
        optimize_by.key = 'optimize_by';
        optimize_by.value = { 'PRBEP' };
        optimize_by.shouldMatch = 1;
    end
    
    %% createTables
    
    function createTables(this)
        graph.key = 'graph';
        graphNames = { {'webkb_constructed'} };
                       %{'reuters_4_topics.tfidf.graph'}, ...
                       %{'farmer-d.tfidf.graph'}, ...
                       %{'kaminski-v.tfidf.graph'}, ...
                       %{'books_dvd_music.tfidf.graph'} };
                      %{'twentyNG_4715'}, {'sentiment_5k'}};
        graph.shouldMatch = 1;
        balanced.key = 'balanced';
        balanced.value = {'0'};
        balanced.shouldMatch = 1;
        num_labeled.key = 'num labeled';
        num_labeled.value = {'48'};
        num_labeled.shouldMatch = 1;
        labeled_init.key = 'labelled init';
        
        labeled_init.shouldMatch = 1;
%         optimize_by.key = 'optimize_by';
%         optimize_by.shouldMatch = 1;
        
        table_i = 1;
        
        %optimize_by.value = { 'PRBEP' };
        labeled_init.value = {'1'};
        searchProperties{table_i} = [balanced num_labeled labeled_init];
        table_i = table_i + 1;

        %optimize_by.value = { 'macroACC' };
%         searchProperties{table_i} = [balanced num_labeled labeled_init];
%         table_i = table_i + 1;

%         optimize_by.value = { 'PRBEP' };
%         labeled_init.value = {'2'};
%         searchProperties{table_i} = [balanced num_labeled labeled_init optimize_by];
%         table_i = table_i + 1;
% 
%         optimize_by.value = { 'macroACC' };
%         searchProperties{table_i} = [balanced num_labeled labeled_init optimize_by];
%         table_i = table_i + 1;

        outputFileName = [this.inputFileName() '.tex'];
        outputFileID = fopen(outputFileName, 'w+');
        
        for table_i=1:length(searchProperties)
            this.startTable( outputFileID );
        
            for graph_i = 1:length(graphNames)
                graph.value = graphNames{graph_i};
                this.printOneDataset(outputFileID, graph.value{1}, ...
                    [graph searchProperties{table_i}]);
            end
            this.endTable( outputFileID, graph.value{1}, ...
                [graph searchProperties{table_i}] );
        end
        fclose(outputFileID);
    end
    
    %% findAlgorithms
    
    function R = findAlgorithms(this, searchProperties)
        
        heuristics.key = 'heuristics';
        heuristics.value = {'0'};
        heuristics.shouldMatch = 1;
        
        algorithm.key = 'Algorithm';
        algorithm.shouldMatch = 1;
        
        algorithm.value = {CSSLMC.name()};
        diag = this.findEntries([searchProperties heuristics algorithm]);
        assert( length(diag) == 1);
        diag = diag {1};
        
%         algorithm.value = {CSSLMCF.name()};
%         full = this.findEntries([searchProperties heuristics algorithm]);
%         assert( length(full) == 1);
%         full = full {1};
        
        algorithm.value = {AM.name()};
        am = this.findEntries([searchProperties heuristics algorithm]);
        assert( length(am) == 1);
        am = am{1};
        
        heuristics.value = {'1'};
        
        algorithm.value = {MAD.name()};
        mad = this.findEntries([searchProperties heuristics algorithm]);
        assert( length(mad) == 1);
        mad = mad{1};
        
        R.diag = diag;
        R.am = am;
        R.mad = mad;
    end
    
    %% printOneDataset
    
    function printOneDataset(this, outputFile, dataSetName, ...
                             searchProperties )
        optimize_by.key = 'optimize_by';
        optimize_by.shouldMatch = 1;
        
        Logger.log( ['printOneDataset. data set name = ' dataSetName] );

        optimize_by.value = { 'PRBEP' };
        PRBEP = this.findAlgorithms([searchProperties optimize_by]);
        
        optimize_by.value = { 'macroACC' };
        macroAcc = this.findAlgorithms([searchProperties optimize_by]);
        
        trimPosition = find(~isletter(dataSetName));
        if (~isempty(trimPosition))
            dataSetName = dataSetName(1:(trimPosition-1));
        end
        numLabeled = [PRBEP.diag('num labeled') ' labeled' ];
        
        lineFormat = ['%s    & %s  & %s & %s & %s & %s & %s & %s \\\\ \\cline{2-8}\n'];

        key = 'avg PRBEP';
        metricName = 'PRBEP';
        this.printLine(outputFile, lineFormat, key, [], PRBEP, macroAcc, metricName );
        
        key = 'avg accuracy';    
        metricName = 'ACC';
        this.printLine(outputFile, lineFormat, key, ['\' dataSetName], PRBEP, macroAcc, metricName );
        
        key = 'avg macro accuracy'; 
        metricName = 'M-ACC';
        this.printLine(outputFile, lineFormat, key, numLabeled, PRBEP, macroAcc, metricName );
        
        key = 'avg MRR'; 
        metricName = 'MRR';
        this.printLine(outputFile, lineFormat, key, [], PRBEP, macroAcc, metricName );
        
        key = 'avg macro MRR'; 
        metricName = 'M-MRR';
        this.printLine(outputFile, lineFormat, key, [], PRBEP, macroAcc, metricName );
    end
    
    %% printLine
    
    function printLine(this, outputFile, lineFormat, ...
                       key, linePrefix, PRBEP, macroAcc, metricName)
        optimizePRBEP_results    = this.metricToString(key, PRBEP);
        optimizeMacroAcc_results = this.metricToString(key, macroAcc);
        fprintf(outputFile, lineFormat, ...
                            linePrefix, metricName, ...
                            optimizePRBEP_results{1}, ...
                            optimizePRBEP_results{2}, ...
                            optimizePRBEP_results{3}, ...
                            optimizeMacroAcc_results{1},...
                            optimizeMacroAcc_results{2},...
                            optimizeMacroAcc_results{3}...
                            );
    end
    
    %% metricToString
    
    function R = metricToString(~, key, algorithms)
        stringValues = {    algorithms.mad(key);
                            algorithms.am(key);
                            algorithms.diag(key) };
        numeriaclValues = 100 * str2num(char(stringValues));
        [~, maxPosition] = max(numeriaclValues);
        stringValues = cellstr(num2str(numeriaclValues, '%.2f'));
        stringValues{maxPosition} = ['\textbf{' stringValues{maxPosition} '}'];
        R = stringValues;
    end
        
    %% startTable
    
    function startTable(~, outputFile)
        fprintf(outputFile, '\\begin{table}\n');
        fprintf(outputFile, '\\centering\n');
        fprintf(outputFile, '\\begin{tabular}{ | c | c || c | c | c || c | c | c | }\n');
        fprintf(outputFile, '\\hline\n');
        fprintf(outputFile, '\\multicolumn{2}{|c||}{}  & \\multicolumn{3}{|c||}{Optimized by} & \\multicolumn{3}{|c|}{Optimized by} \\\\\n');
        fprintf(outputFile, '\\multicolumn{2}{|c||}{}  & \\multicolumn{3}{|c||}{PRBEP}        & \\multicolumn{3}{|c|}{M-ACC} \\\\ \\cline{3-8}\n');
        fprintf(outputFile, '\\multicolumn{2}{|c||}{}  & MAD & AM  & \\algorithmName           & MAD & AM  & \\algorithmName \\\\ \\hline\n');
    end
    
    %% endTable
    
    function endTable(this, outputFile, dataSetName, searchProperties )
        
        algorithm.key = 'Algorithm';
        algorithm.shouldMatch = 1;

        heuristics.key = 'heuristics';
        heuristics.value = {'0'};
        heuristics.shouldMatch = 1;
        
        optimize_by.key = 'optimize_by';
        optimize_by.shouldMatch = 1;
        optimize_by.value = { 'PRBEP' };
        
        algorithm.value = {CSSLMC.name()};
        diag = this.findEntries([searchProperties optimize_by ...
                                 heuristics algorithm]);
        assert( length(diag) == 1);
        diag = diag {1};

        fprintf(outputFile, '\\hline\n');
        fprintf(outputFile, '\\end{tabular}\n');
        caption = ['results ' ...
                   ' prior init mode ' diag('labelled init') ...
                   ' balanced ' diag('balanced')
                   ];
                   
        fprintf(outputFile, '\\caption{%s}\n', caption);
        fprintf(outputFile, '\\label{tab:table_multiple_datasets}\n' );
        fprintf(outputFile, '\\end{table}\n');
    end
    
    %% findEntries
    
    function R = findEntries( this, searchProperties)
        found_i = 0;
        searchKeys     = {searchProperties.key};
        searchValues   = {searchProperties.value};
        shouldMatch    = [searchProperties.shouldMatch];

        for result_i=1:length(this.m_resultMaps)
            map = this.m_resultMaps{result_i};
            isMatch = 1;
            for key_i = 1:length(searchKeys)
                key                  = searchKeys{key_i};
                possibleSearchValues = searchValues{key_i};
                foundValue = 0;
                for value_i=1:length(possibleSearchValues);
                    expectedValue   = possibleSearchValues{value_i};
                    if strcmp(map(key), expectedValue) == shouldMatch(key_i)
                        foundValue = 1;
                        break;
                    end
                end
                if 0 == foundValue
                    isMatch = 0;
                    break;
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
        fileName = ['C:\technion\theses\Experiments\results\For Paper\' ...
                    'BigTableSummary.txt'];
        this.clearAll();
        this.convert(fileName);
    end
end
    
end

