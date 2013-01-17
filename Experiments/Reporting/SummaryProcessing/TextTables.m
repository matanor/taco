classdef TextTables < TextReporterBase

methods (Access  = private)
   
%% createTables_ecml2012

function createTables_ecml2012(this)

    nlpGraphNames = this.nlpGraphNames();
    numLabeledPerGraph = this.numLabeledPerGraphForTables();

    graph.key = 'graph';
    graph.shouldMatch = 1;

    balanced.key = 'balanced';
    balanced.value = {'0'};
    balanced.shouldMatch = 1;

    num_iterations.key = 'max iterations';
    num_iterations.value = {'10'};
    num_iterations.shouldMatch = 1;

    num_labeled.key = 'num labeled';


    num_labeled.shouldMatch = 1;
    labeled_init.key = 'labelled init';
    labeled_init.shouldMatch = 1;
    labeled_init.value = {'1'}; % Hoe data is initialized

%         optimize_by.key = 'optimize_by';
%         optimize_by.shouldMatch = 1;

    table_i = 1;

    %optimize_by.value = { 'PRBEP' };

    searchProperties{table_i} = [balanced labeled_init num_iterations];
    optimizeBy.leftColumn {table_i} = 'PRBEP';
    optimizeBy.rightColumn{table_i} = 'macroACC';
    optimizeBy.leftName{table_i}    = 'PRBEP';
    optimizeBy.rightName{table_i}   = 'M-ACC';
    table_i = table_i + 1;

    searchProperties{table_i} = [balanced labeled_init num_iterations];
    optimizeBy.leftColumn {table_i} = 'accuracy';
    optimizeBy.rightColumn{table_i} = 'MRR';
    optimizeBy.leftName{table_i}    = 'accuracy';
    optimizeBy.rightName{table_i}   = 'MRR';
    table_i = table_i + 1;

    searchProperties{table_i} = [balanced labeled_init num_iterations];
    optimizeBy.leftColumn {table_i} = 'macroACC';
    optimizeBy.rightColumn{table_i} = 'macroMRR';
    optimizeBy.leftName{table_i}    = 'M-ACC';
    optimizeBy.rightName{table_i}   = 'M-MRR';
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

    outputFileName = [this.inputFileName() '.ecml2012.tex'];
    outputFileID = fopen(outputFileName, 'w+');

    for table_i=1:length(searchProperties)

        Logger.log( ['createTables_ecml2012. table_i = ' num2str(table_i)] );
        this.startTable_ecml2012( outputFileID, ...
                                  optimizeBy.leftName{table_i}, ...
                                  optimizeBy.rightName{table_i});

        for graph_i = 1:length(nlpGraphNames)
            graph.value = nlpGraphNames(graph_i);
            num_labeled.value = numLabeledPerGraph(graph_i);
            this.printOneDataset(outputFileID, graph.value{1}, ...
                [num_labeled graph searchProperties{table_i}], ...
                optimizeBy.leftColumn{table_i}, ...
                optimizeBy.rightColumn{table_i});
        end
        this.endTable_ecml2012( outputFileID, ...
            [num_labeled graph searchProperties{table_i}] );
    end
    fclose(outputFileID);
end

%% printOneDataset

function printOneDataset(this, outputFile, dataSetName, ...
                         searchProperties, optimizeByLeftColumn, optimizeByRightColumn )
    optimize_by.key = 'optimize_by';
    optimize_by.shouldMatch = 1;

    Logger.log( ['printOneDataset. data set name = ' dataSetName] );

    optimize_by.value = { optimizeByLeftColumn }; %'PRBEP' };
    leftColumnResult = this.findAlgorithms([searchProperties optimize_by]);

    optimize_by.value = { optimizeByRightColumn }; %'macroACC' };
    rightColumnResults = this.findAlgorithms([searchProperties optimize_by]);

    trimPosition = find(~isletter(dataSetName));
    if (~isempty(trimPosition))
        dataSetName = dataSetName(1:(trimPosition-1));
    end
    numLabeled = [leftColumnResult.diag('num labeled') ' labeled' ];

    lineFormat = ['%s    & ~%s~  & ~%s~ & ~%s~ & ~%s~ & ~%s~ & ~%s~ & ~%s~ \\\\ \\cline{%s-8}\n'];

    key = 'avg PRBEP';
    metricName = 'PRBEP';
    columnStartHorzLine = '2';
    %fprintf(outputFile, '\\\\ \\hline\n');
    fprintf(outputFile, '\\hline \\hline\n');
    this.printLine(outputFile, lineFormat, key, [], ...
                    leftColumnResult, rightColumnResults, metricName, columnStartHorzLine );

    key = 'avg accuracy';    
    metricName = 'ACC';
    this.printLine(outputFile, lineFormat, key, ['\' dataSetName],...
                    leftColumnResult, rightColumnResults, metricName, columnStartHorzLine );

    key = 'avg macro accuracy'; 
    metricName = 'M-ACC';
    this.printLine(outputFile, lineFormat, key, numLabeled, ...
                    leftColumnResult, rightColumnResults, metricName, columnStartHorzLine );

    key = 'avg MRR'; 
    metricName = 'MRR';
    this.printLine(outputFile, lineFormat, key, [],...
                    leftColumnResult, rightColumnResults, metricName, columnStartHorzLine );

    key = 'avg macro MRR'; 
    metricName = 'M-MRR';
    columnStartHorzLine = '1';
    this.printLine(outputFile, lineFormat, key, [],...
                    leftColumnResult, rightColumnResults, metricName, columnStartHorzLine );
end

%% printLine

function printLine(this, outputFile, lineFormat, ...
                   key, linePrefix, leftMetricValues, rightMetricValues,...
                   metricName, columnStartHorzLine)
    leftMetric_results  = this.metricToString(key, leftMetricValues);
    rightMetric_results = this.metricToString(key, rightMetricValues);
    fprintf(outputFile, lineFormat, ...
                        linePrefix, metricName, ...
                        leftMetric_results{1}, ...
                        leftMetric_results{2}, ...
                        leftMetric_results{3}, ...
                        rightMetric_results{1},...
                        rightMetric_results{2},...
                        rightMetric_results{3},...
                        columnStartHorzLine ...
                        );
end

%% metricToString
%  Mark highest values with bold. multiply by 100.
%  e.g. converts stringValues = { '1'; '2'; '2'; }
%  to     '100.0'
%         '\textbf{200.0}'
%         '\textbf{200.0}'

function R = metricToString(~, key, algorithms)
    stringValues = {    algorithms.mad(key);
                        algorithms.am(key);
                        algorithms.diag(key) };
    numericalValues = 100 * str2num(char(stringValues));
    % transform 73.21 -> 73.2 (zero out all digits beyond 1 decimal
    % point)
    numericalValues = round(numericalValues * 10) / 10; 
    maxValue = max(numericalValues);
    positionsWithMaximum = (numericalValues == maxValue);
    stringValues = cellstr(num2str(numericalValues, '%.1f'));
    for position_i=1:length(stringValues)
        if 1 == positionsWithMaximum(position_i)
            stringValues{position_i} = ['\textbf{' stringValues{position_i} '}'];
        end
    end
    R = stringValues;
end

%% startTable_ecml2012

function startTable_ecml2012(~, outputFile, optimizeByLeftName, optimizeByRightName)
    fprintf(outputFile, '\\begin{table}\n');
    fprintf(outputFile, '\\centering\n');
    fprintf(outputFile, '\\begin{tabular}{ | c | c || c | c | c || c | c | c | }\n');
    fprintf(outputFile, '\\hline\n');
    fprintf(outputFile, '\\multicolumn{2}{|c||}{}  & \\multicolumn{3}{|c||}{Optimized by} & \\multicolumn{3}{|c|}{Optimized by} \\\\\n');
    fprintf(outputFile, '\\multicolumn{2}{|c||}{}  & \\multicolumn{3}{|c||}{%s}        & \\multicolumn{3}{|c|}{%s} \\\\ \\cline{3-8}\n', ...
                        optimizeByLeftName, optimizeByRightName);
    fprintf(outputFile, '\\multicolumn{2}{|c||}{}  & MAD & AM  & \\algorithmName           & MAD & AM  & \\algorithmName \\\\ \n');
end

%% endTable_ecml2012

function endTable_ecml2012(this, outputFile, searchProperties )

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
%        caption = ['results ' ...
%                   ' prior init mode ' diag('labelled init') ...
%                   ' balanced ' diag('balanced')
%                    ];
    fprintf(outputFile, '\\vspace{0.5cm}\n');

    fprintf(outputFile, '\\caption{\\multiDataSetsTableCaption}\n');
    fprintf(outputFile, '\\label{tab:table_multiple_datasets}\n' );
    fprintf(outputFile, '\\end{table}\n');
end
    
end % private methods
    
end % classdef