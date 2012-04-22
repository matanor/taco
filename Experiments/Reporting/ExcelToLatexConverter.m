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
        this.createGraphs();
%        this.createTables();
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
        
        outputFileName = [this.inputFileName() '.figs.tex'];
        figuresFileID  = fopen(outputFileName, 'a+');
        
        fprintf(figuresFileID,'\\begin{figure}[t]\n');
        fprintf(figuresFileID,'\\centering\n');

        optimize_by.key = 'optimize_by';
        optimize_by.shouldMatch = 1;

        optimizeByForFileName = 'opt_PRBEP';
        optimize_by.value = { 'PRBEP' };
        
        presentedKey = 'avg PRBEP';
        presentedKeyFileName = 'PRBEP';
        presentedKeyLabelY = 'macro-averaged PRBEP';
        
        fprintf(figuresFileID,'\\mbox{\n');
        % 1 %%%%%%%%%%%%%%%%%%
        
        this.createSingleFigure(figuresFileID, [searchProperties optimize_by], presentedKey, ...
            presentedKeyFileName, presentedKeyLabelY, optimizeByForFileName);

        fprintf(figuresFileID,'\\quad\n');
                
        presentedKey = 'avg macro accuracy';
        presentedKeyFileName = 'M-ACC';
        presentedKeyLabelY = 'macro-averaged accuracy (M-ACC)';
        
        % 2 %%%%%%%%%%%%%%%%%%
        
        this.createSingleFigure(figuresFileID, [searchProperties optimize_by], presentedKey, ...
            presentedKeyFileName, presentedKeyLabelY, optimizeByForFileName);

        fprintf(figuresFileID,'}\\\\\n');
        fprintf(figuresFileID,'\\mbox{\n');

        optimizeByForFileName = 'opt_M-ACC';
        optimize_by.value = { 'macroACC' };

        presentedKey = 'avg macro accuracy';
        presentedKeyFileName = 'M-ACC';
        presentedKeyLabelY = 'macro-averaged accuracy (M-ACC)';

        % 3 %%%%%%%%%%%%%%%%%%
                
        this.createSingleFigure(figuresFileID, [searchProperties optimize_by], presentedKey, ...
            presentedKeyFileName, presentedKeyLabelY, optimizeByForFileName);
        
        fprintf(figuresFileID,'\\quad\n');

        presentedKey = 'avg PRBEP';
        presentedKeyFileName = 'PRBEP';
        presentedKeyLabelY = 'macro-averaged PRBEP';

        % 4 %%%%%%%%%%%%%%%%%%
        
        this.createSingleFigure(figuresFileID, [searchProperties optimize_by], presentedKey, ...
            presentedKeyFileName, presentedKeyLabelY, optimizeByForFileName);
        
        fprintf(figuresFileID,'}\n');

        fprintf(figuresFileID,'\\caption{\\numLabelsCompareCaption}\n');
        fprintf(figuresFileID,'\\label{fig:webkb_num_labeled_comare}\n');
        fprintf(figuresFileID,'\\vspace{-15pt}\n');
        fprintf(figuresFileID,'\\end{figure}\n');

        fclose(figuresFileID);
    end
       
    function createSingleFigure(this, figuresFileID, searchProperties, presentedKey, ...
                                presentedKeyFileName, presentedKeyLabelY,...
                                optimizeByForFileName)
        num_labeled.key = 'num labeled';
        num_labeled.shouldMatch = 1;

        numLabeledRange = {'24', '48', '96', '192', '500'};
        numAlgorithms = 3;
        stddevKey       = this.stddevKay(presentedKey);
        barSource = zeros(length(numLabeledRange), numAlgorithms);
        stddev = zeros( size(barSource) );
        MAD = 1;        AM = 2; CSSL = 3;
        for numLabeled_i=1:length(numLabeledRange)
            num_labeled.value = numLabeledRange(numLabeled_i);
            algorithms = this.findAlgorithms([searchProperties num_labeled]);
            barSource(numLabeled_i , MAD) = str2num(algorithms.mad( presentedKey ));
            barSource(numLabeled_i , AM) = str2num(algorithms.am( presentedKey )) ;
            barSource(numLabeled_i , CSSL) = str2num(algorithms.diag( presentedKey )) ;
            stddev(numLabeled_i , MAD) = str2num(algorithms.mad( stddevKey ));
            stddev(numLabeled_i , AM) = str2num(algorithms.am( stddevKey ));
            stddev(numLabeled_i , CSSL) = str2num(algorithms.diag( stddevKey ));
        end
        
        % barSource size is num options * num_algorithm
        h = figure;
        barSource = barSource * 100;
        stddev = (1.96 / sqrt(20)) * stddev * 100;
        grid on;
        numLabeledRangeMatrix = str2num(char(numLabeledRange));
        hold on;
        algorithm = MAD;
        lineWidth = 3.5;
        markerSize = 11;
        errorbar(numLabeledRangeMatrix,barSource(:,algorithm), stddev(:,algorithm),...
                '-bs','LineWidth',lineWidth,...
                'MarkerEdgeColor','b',...
                'MarkerFaceColor','w',...
                'MarkerSize',markerSize);
        algorithm = AM;
        errorbar(numLabeledRangeMatrix,barSource(:,algorithm), stddev(:,algorithm),...
                '-gd','LineWidth',lineWidth,...
                'MarkerEdgeColor','g',...
                'MarkerFaceColor','w',...
                'MarkerSize',markerSize);
        algorithm = CSSL;
        errorbar(numLabeledRangeMatrix,barSource(:,algorithm), stddev(:,algorithm),...
                '-ro','LineWidth',lineWidth,...
                'MarkerEdgeColor','r',...
                'MarkerFaceColor','w',...
                'MarkerSize',markerSize);
        %bar(barSource,'hist');
        %set(gca,'XTickLabel',numLabeledRange);
        set(gca, 'FontSize', 18);
        legend('MAD','AM','CSSL', 'Location', 'SouthEast');
        xlabel('Number of Labeled Examples');
        highLimitY = max(barSource(:)) * 1.05;
        lowLimitY  = min(barSource(:)) * 0.9;
        set(gca,'YLim',[lowLimitY highLimitY]);
        set(gca,'XGrid','off','YGrid','on')
        ylabel(presentedKeyLabelY);
        directory = 'C:\technion\theses\Tex\SSL\GraphSSL_Confidence_Paper\';
        fileName = ['compare_num_labelled_' optimizeByForFileName '_' presentedKeyFileName] ;
        fileFullPath = [ directory fileName '.pdf'];
        saveas(h, fileFullPath ); 
        close(h);
        
        x = find(optimizeByForFileName=='_');
        if ~isempty(x)
            optimizeByForFileName = optimizeByForFileName(x+1:end);
        end
        caption = [presentedKeyFileName ' tuned according to ' optimizeByForFileName];

        fprintf(figuresFileID,'\\subfigure[%s]\n', caption);
        fprintf(figuresFileID,'{\\label{fig:%s}\n', fileName); 
        fprintf(figuresFileID,'\\includegraphics[width=55mm,angle=0,trim = 15mm 65mm 10mm 65mm, clip]{%s}\n',...
                                fileName);
        fprintf(figuresFileID,'}\n');
    end
    
    %% createTables
    
    function createTables(this)
        graph.key = 'graph';
        graphNames = { ...
                       {'webkb_constructed'} , ...
                       {'twentyNG_4715'}, ...
                       {'sentiment_5k'} ...
                       {'reuters_4_topics.tfidf.graph'}, ...
                       {'farmer-d.tfidf.graph'}, ...
                       {'kaminski-v.tfidf.graph'}, ...
                       {'books_dvd_music.tfidf.graph'} ...
                       };
        numLabeledPerGraph = { '48' , ...
                       '105', ...
                       '500' ...
                       '48', ...
                       '48', ...
                       '48', ...
                       '35' ...
                       };
        graph.shouldMatch = 1;
        balanced.key = 'balanced';
        balanced.value = {'0'};
        balanced.shouldMatch = 1;
        num_labeled.key = 'num labeled';
        
        num_iterations.key = 'max iterations';
        num_iterations.value = {'10'};
        num_iterations.shouldMatch = 1;
        
        num_labeled.shouldMatch = 1;
        labeled_init.key = 'labelled init';
        
        labeled_init.shouldMatch = 1;
%         optimize_by.key = 'optimize_by';
%         optimize_by.shouldMatch = 1;
        
        table_i = 1;
        
        %optimize_by.value = { 'PRBEP' };
        labeled_init.value = {'1'};
        searchProperties{table_i} = [balanced labeled_init num_iterations];
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
                num_labeled.value = numLabeledPerGraph(graph_i);
                this.printOneDataset(outputFileID, graph.value{1}, ...
                    [num_labeled graph searchProperties{table_i}]);
            end
            this.endTable( outputFileID, ...
                [num_labeled graph searchProperties{table_i}] );
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
        
        lineFormat = ['%s    & ~%s~  & ~%s~ & ~%s~ & ~%s~ & ~%s~ & ~%s~ & ~%s~ \\\\ \\cline{%s-8}\n'];

        key = 'avg PRBEP';
        metricName = 'PRBEP';
        columnStartHorzLine = '2';
        %fprintf(outputFile, '\\\\ \\hline\n');
        fprintf(outputFile, '\\hline \\hline\n');
        this.printLine(outputFile, lineFormat, key, [], ...
                        PRBEP, macroAcc, metricName, columnStartHorzLine );
        
        key = 'avg accuracy';    
        metricName = 'ACC';
        this.printLine(outputFile, lineFormat, key, ['\' dataSetName],...
                        PRBEP, macroAcc, metricName, columnStartHorzLine );
        
        key = 'avg macro accuracy'; 
        metricName = 'M-ACC';
        this.printLine(outputFile, lineFormat, key, numLabeled, ...
                        PRBEP, macroAcc, metricName, columnStartHorzLine );
        
        key = 'avg MRR'; 
        metricName = 'MRR';
        this.printLine(outputFile, lineFormat, key, [],...
                        PRBEP, macroAcc, metricName, columnStartHorzLine );
        
        key = 'avg macro MRR'; 
        metricName = 'M-MRR';
        columnStartHorzLine = '1';
        this.printLine(outputFile, lineFormat, key, [],...
                        PRBEP, macroAcc, metricName, columnStartHorzLine );
    end
    
    %% printLine
    
    function printLine(this, outputFile, lineFormat, ...
                       key, linePrefix, PRBEP, macroAcc, metricName,...
                       columnStartHorzLine)
        optimizePRBEP_results    = this.metricToString(key, PRBEP);
        optimizeMacroAcc_results = this.metricToString(key, macroAcc);
        fprintf(outputFile, lineFormat, ...
                            linePrefix, metricName, ...
                            optimizePRBEP_results{1}, ...
                            optimizePRBEP_results{2}, ...
                            optimizePRBEP_results{3}, ...
                            optimizeMacroAcc_results{1},...
                            optimizeMacroAcc_results{2},...
                            optimizeMacroAcc_results{3},...
                            columnStartHorzLine ...
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
        fprintf(outputFile, '\\multicolumn{2}{|c||}{}  & MAD & AM  & \\algorithmName           & MAD & AM  & \\algorithmName \\\\ \n');
    end
    
    %% endTable
    
    function endTable(this, outputFile, searchProperties )
        
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
        fprintf(outputFile, '\\vspace{0.5cm}\n');
                   
        fprintf(outputFile, '\\caption{\\multiDataSetsTableCaption}\n');
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
                originalValue   = map(key);
                map(key)        = this.trim(originalValue);
                sttdev          = this.parseStddev(originalValue);
                stddevKey       = this.stddevKay(key);
                map(stddevKey)  = sttdev;
            end
            this.m_resultMaps{result_i} = map;
        end        
    end
    
    %% stddevKay
    
    function R = stddevKay(~,key)
        R = ['stddev ' key];
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
    
    %% parseStddev
    
    function S = parseStddev(~,S)
        trimStart = find( S == '(' );
        trimEnd = find( S == ')' );
        if ~isempty(trimStart) && ~isempty(trimEnd)
            S = S(trimStart+1:trimEnd-1);
        else
            Logger.log(['parseStddev::Error. Cannot trim value ''' S '''']);
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

