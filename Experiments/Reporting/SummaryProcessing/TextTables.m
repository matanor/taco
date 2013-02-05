classdef TextTables < TextReporterBase
 
methods (Static)

%% office
% fileName = 'C:/technion/theses/Tex/SSL/Thesis/Results/thesis_results.txt';
%% home
% fileName = 'E:/technion/theses/Tex/SSL/Thesis/Results/thesis_results.txt';

%% run

function run(fileName)
    this = TextTables();
    this.convert(fileName);
end

%% outputDirectory

function R = outputDirectory()
    R = 'E:/technion/theses/Tex/SSL/Thesis/';
end

end % static methods

methods (Access = public)
    
%% doConvert

function doConvert(this)
%     this.createTables_ecml2012();

%     results = this.gatherResults_tacoVariants();
%     this.outputTable(results);
%     this.outputAverageResultsTable(results);

    tacoVariantsResults  = this.gatherResults_tacoVariants();
    tacoBaselinesResults = this.gatherResults_tacoBaseLines();
    
    for isTacoVariants = [0 1]
        optimizeByMetric = [];
        if isTacoVariants
            results = tacoVariantsResults;
        else
            results = tacoBaselinesResults;
        end
        
        this.outputAverageResultsTable(results, isTacoVariants, optimizeByMetric);
    
        optimizeByMetric = MetricProperties.PRBEP;
        this.outputAverageResultsTable(results, isTacoVariants, optimizeByMetric);
    
        optimizeByMetric = MetricProperties.MACRO_ACC;
        this.outputAverageResultsTable(results, isTacoVariants, optimizeByMetric);
    end
end

end % overrides

methods (Access  = private)

%% outputAverageResultsTable

function outputAverageResultsTable(this, results, isTacoVariants, optimizeByMetric)
    nlpGraphNames       = this.nlpGraphNames();
    TACO_variants_order = this.TACO_variants_order();
    metricKeys          = MetricProperties.metricKeys();
    metricShortNames    = MetricProperties.metricShortNames();
    metricOrderInTables = this.metricOrderInTables();
    if ~isempty(optimizeByMetric)
        optimizeByMetricName= metricShortNames{optimizeByMetric};
    else
        optimizeByMetricName = 'none';
    end
    
    Logger.log(['TextTables::doConvert. isTacoVariants = '    num2str(isTacoVariants) ... 
                                    ' optimizeByMetricName = ''' optimizeByMetricName '''']);
    
    allAverageResults = [];
    for metric_ID = metricOrderInTables
      numericResults = [];
      for graph_i =1:length(nlpGraphNames)
          presentedKey = metricKeys{metric_ID};
          if isempty(optimizeByMetric)
              metric_for_results = metric_ID;
          else
              metric_for_results = optimizeByMetric;
          end
          if isTacoVariants
            singleResults = results(graph_i,metric_for_results,:); 
            stringResults = TextTables.tacoVariantsResults_toStrings...
                   (singleResults, TACO_variants_order, presentedKey);
          else
            singleResults = results(graph_i,metric_for_results); 
            singleResults = singleResults{1};
            stringResults = this.baselines_toStrings(presentedKey, singleResults);
          end
          numericResults(graph_i,:) = cellfun(@str2num,stringResults); %#ok<AGROW>
      end
      averageMetricResults = mean(numericResults,1);
      rowKey = metricShortNames{metric_ID};
      TextTables.averageTable_printLine(averageMetricResults, rowKey);
      allAverageResults = [allAverageResults; averageMetricResults]; %#ok<AGROW>       
    end
    totalAverage = mean(allAverageResults, 1);
    TextTables.averageTable_printLine(totalAverage, 'Average');
end

%% outputTable

function outputTable(this, results)
    nlpGraphNames = this.nlpGraphNames();
    
    leftMetric_ID  = MetricProperties.PRBEP;
    rightMetric_ID = MetricProperties.MACRO_ACC;
    isTacoVariants = 1;
    outputFile = 1;
    
    allResults = [];
    for graph_i =1:length(nlpGraphNames)
        dataSetName = nlpGraphNames{graph_i};
%         Logger.log(['TextTables::outputTable. graph name = ''' dataSetName '''']);
        leftColumnResult   = results(graph_i,leftMetric_ID,:);
        rightColumnResults = results(graph_i,rightMetric_ID,:);
        dataSetResults = this.printOneDataset(outputFile, dataSetName, ...
                                leftColumnResult, rightColumnResults, isTacoVariants);
        allResults = [allResults; dataSetResults]; %#ok<AGROW>
    end
    totalAverage = mean(allResults, 1);
    total_left   = totalAverage(1:4).';
    total_right  = totalAverage(5:8).';
    this.printLine(outputFile, [], [], ...
                    cellstr(num2str(total_left)) , cellstr(num2str(total_right)), '1');
    
    for metric_i = 1:5
        dataForMetric = allResults(metric_i:5:end,:);
        metricAverage = mean(dataForMetric,1);
        metricAverage_left   = metricAverage(1:4).';
        metricAverage_right  = metricAverage(5:8).';
        this.printLine(outputFile, [], [], ...
                    cellstr(num2str(metricAverage_left)) , cellstr(num2str(metricAverage_right)), '1');
    end
end

%% createTables_ecml2012

function createTables_ecml2012(this)

    nlpGraphNames       = this.nlpGraphNames();
    numLabeledPerGraph  = this.numLabeledPerGraphForTables();

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
    
    taco_objective.key = 'TACO objective';
    taco_objective.value = {num2str(CSSLBase.OBJECTIVE_HARMONIC_MEAN)};
    taco_objective.shouldMatch = 1;

%         optimize_by.key = 'optimize_by';
%         optimize_by.shouldMatch = 1;

    table_i = 1;

    %optimize_by.value = { 'PRBEP' };
    generalSearchProperties = [balanced labeled_init num_iterations taco_objective];

    searchProperties{table_i} = generalSearchProperties;
    optimizeBy.leftColumn {table_i} = 'PRBEP';
    optimizeBy.rightColumn{table_i} = 'macroACC';
    optimizeBy.leftName{table_i}    = 'PRBEP';
    optimizeBy.rightName{table_i}   = 'M-ACC';
    table_i = table_i + 1;

%     searchProperties{table_i} = generalSearchProperties;
%     optimizeBy.leftColumn {table_i} = 'accuracy';
%     optimizeBy.rightColumn{table_i} = 'MRR';
%     optimizeBy.leftName{table_i}    = 'accuracy';
%     optimizeBy.rightName{table_i}   = 'MRR';
%     table_i = table_i + 1;
% 
%     searchProperties{table_i} = generalSearchProperties;
%     optimizeBy.leftColumn {table_i} = 'macroACC';
%     optimizeBy.rightColumn{table_i} = 'macroMRR';
%     optimizeBy.leftName{table_i}    = 'M-ACC';
%     optimizeBy.rightName{table_i}   = 'M-MRR';
%     table_i = table_i + 1;

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

    [~, inputFileNameOnly, ~] = fileparts(this.inputFileName());
    outputFileName = [TextTables.outputDirectory() inputFileNameOnly '.ecml2012.tex'];
    Logger.log(['TextTables::create. Opening output ''' outputFileName '''']);
    outputFileID = fopen(outputFileName, 'w+');
    if (-1 == outputFileID)
        Logger.log(['TextTables::create. Unable to open output file ''' outputFileName '''']);
        return;
    end

    for table_i=1:length(searchProperties)

        Logger.log( ['createTables_ecml2012. table_i = ' num2str(table_i)] );
        TextTables.startTable_ecml2012( outputFileID, ...
                                  optimizeBy.leftName{table_i}, ...
                                  optimizeBy.rightName{table_i});

        for graph_i = 1:length(nlpGraphNames)
            graph.value = nlpGraphNames(graph_i);
            num_labeled.value = numLabeledPerGraph(graph_i);
            this.gatherAndPrintOneDataset(outputFileID, graph.value{1}, ...
                [num_labeled graph searchProperties{table_i}], ...
                optimizeBy.leftColumn{table_i}, ...
                optimizeBy.rightColumn{table_i});
        end
        TextTables.endTable_ecml2012( outputFileID );
    end
    fclose(outputFileID);
end

%% gatherAndPrintOneDataset

function gatherAndPrintOneDataset(this, outputFile, dataSetName, ...
                                  searchProperties, optimizeByLeftColumn, optimizeByRightColumn )
    optimize_by.key = 'optimize_by';
    optimize_by.shouldMatch = 1;

    Logger.log( ['gatherAndPrintOneDataset. data set name = ' dataSetName] );

    optimize_by.value = { optimizeByLeftColumn }; %'PRBEP' };
    leftColumnResult = this.findAlgorithms([searchProperties optimize_by]);

    optimize_by.value = { optimizeByRightColumn }; %'macroACC' };
    rightColumnResults = this.findAlgorithms([searchProperties optimize_by]);
    
    isTacoVariants = 0;
    this.printOneDataset(outputFile, dataSetName, ...
                         leftColumnResult, rightColumnResults, isTacoVariants);
end

%% printOneDataset

function R = printOneDataset(this, outputFile, dataSetName, ...
                         leftColumnResult, rightColumnResults, isTacoVariants)
    trimPosition = find(~isletter(dataSetName));
    if (~isempty(trimPosition))
        dataSetName = dataSetName(1:(trimPosition-1));
    end
    if ~isTacoVariants
        tacoResults = leftColumnResult.diag; 
    else
        tacoResults = leftColumnResult{CSSLBase.OBJECTIVE_HARMONIC_MEAN};
        tacoResults = tacoResults{1};
    end
    numLabeled = [tacoResults('num labeled') ' labeled' ];

%     columnStartHorzLine = '2';
    %fprintf(outputFile, '\\\\ \\hline\n');
    fprintf(outputFile, '\\hline \\hline\n');

    metricKeys          = MetricProperties.metricKeys();
    metricShortNames    = MetricProperties.metricShortNames();
    allLinePrefix       = {[], ['\' dataSetName], numLabeled, [], []};
    
    metricOrderInTables = this.metricOrderInTables();
    numMetrics = length(metricOrderInTables);
    metric_i = 1;
    for metricID = metricOrderInTables
        key         = metricKeys{metricID};
        metricName  = metricShortNames{metricID};
        isLastMertic = (metric_i == numMetrics);
        linePrefix  = allLinePrefix{metric_i};
        if isLastMertic
            columnStartHorzLine = '1';
        else
            columnStartHorzLine = '2';
        end
        lineContents(metric_i,:) = ...
                    this.createAndPrintLine(outputFile, key, linePrefix, ...
                    leftColumnResult, rightColumnResults, metricName, columnStartHorzLine, ...
                    isTacoVariants); %#ok<AGROW>
        metric_i = metric_i + 1;
    end
    avgDataSetPerformance = mean(lineContents, 1);
    leftPartAvgerage = avgDataSetPerformance(1:4).';
    rightPartAverage = avgDataSetPerformance(5:8).';
    this.printLine(outputFile, [], [], ...
                    cellstr(num2str(leftPartAvgerage)) , cellstr(num2str(rightPartAverage)), '1');
	R = lineContents;
end

%% createAndPrintLine

function R = createAndPrintLine(this, outputFile, ...
                   key, linePrefix, leftMetricValues, rightMetricValues,...
                   metricName, columnStartHorzLine, isTacoVariants)
    if ~isTacoVariants
        leftMetric_stringResults  = this.baselines_toStrings(key, leftMetricValues);
        rightMetric_stringResults = this.baselines_toStrings(key, rightMetricValues);
    else
        TACO_variants_order = this.TACO_variants_order();
        leftMetric_stringResults = TextTables.tacoVariantsResults_toStrings...
            (leftMetricValues, TACO_variants_order, key);
        rightMetric_stringResults = TextTables.tacoVariantsResults_toStrings...
            (rightMetricValues, TACO_variants_order, key);
    end
    TextTables.printLine(outputFile, linePrefix, metricName,...
                         leftMetric_stringResults, rightMetric_stringResults, columnStartHorzLine);
    numericResults = cellfun(@str2num,[leftMetric_stringResults rightMetric_stringResults]);
	R = numericResults;
end

end % private methods

methods (Static)

%% averageTable_printLine

function averageTable_printLine(numericResults, lineKey)
    avgResultsFormat    = '~%s~  & ~%s~ & ~%s~ & ~%s~ & ~%s~  \\\\ \\hline\n';
    stringResults   = cellstr(num2str(numericResults.'));
    resultsForPrint = TextTables.markBoldStrings(stringResults, 100);      
       fprintf( avgResultsFormat, ...
                lineKey,resultsForPrint{1}, ...
                resultsForPrint{2}, ...
                resultsForPrint{3}, ...
                resultsForPrint{4}  ...
              );
end
    
%% printLine

function printLine(outputFile, linePrefix, metricName, ...
                    leftMetric_stringResults, rightMetric_stringResults, columnStartHorzLine)
    leftMetric_results  = TextTables.markBoldStrings(leftMetric_stringResults, 100);
    rightMetric_results = TextTables.markBoldStrings(rightMetric_stringResults, 100);
    lineFormat = '%s    & %s  & %s & %s & %s & %s & %s & %s & %s & %s \\\\ \\cline{%s-10}\n';
    fprintf(outputFile, lineFormat, ...
                        linePrefix, metricName, ...
                        leftMetric_results{1}, ...
                        leftMetric_results{2}, ...
                        leftMetric_results{3}, ...
                        leftMetric_results{4}, ...
                        rightMetric_results{1},...
                        rightMetric_results{2},...
                        rightMetric_results{3},...
                        rightMetric_results{4},...
                        columnStartHorzLine ...
                        );
end
    
%% tacoVariantsResults_toStrings

function R = tacoVariantsResults_toStrings( resultAllVariants, TACO_variants_order, presentedKey )
    taco_variant_i = 1;
    for TACO_variant_ID = TACO_variants_order
        variantResult = resultAllVariants{TACO_variant_ID};
        variantResult = variantResult{1};
        stringValues{taco_variant_i}  = variantResult(presentedKey); %#ok<AGROW>
        taco_variant_i                = taco_variant_i + 1;
    end
    R = stringValues;
end

%% baselines_toStrings

function R = baselines_toStrings(key, algorithms)
    stringValues = {    algorithms.mad(key);
                        algorithms.am(key);
                        algorithms.qc(key);
                        algorithms.diag(key)};
    R = stringValues;
end

%% markBoldStrings

%  Mark highest values with bold. multiply by <multiplyFactor>.
%  e.g. converts stringValues = { '1'; '2'; '2'; }
%  to     '100.0'
%         '\textbf{200.0}'
%         '\textbf{200.0}'

function R = markBoldStrings(stringValues, multiplyFactor)
    numericalValues = multiplyFactor * str2num(char(stringValues));
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

function startTable_ecml2012( outputFile, optimizeByLeftName, optimizeByRightName)
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
    
function endTable_ecml2012( outputFile )
    fprintf(outputFile, '\\hline\n');
    fprintf(outputFile, '\\end{tabular}\n');
    fprintf(outputFile, '\\caption{\\multiDataSetsTableCaption}\n');
    fprintf(outputFile, '\\label{tab:table_multiple_datasets}\n' );
    fprintf(outputFile, '\\end{table}\n');
end

%% TACO_variants_order

function R = TACO_variants_order()
    R = [CSSLBase.OBJECTIVE_HARMONIC_MEAN_SINGLE ...
         CSSLBase.OBJECTIVE_HARMONIC_MEAN        ...CSSLBase.OBJECTIVE_MULTIPLICATIVE             ...
         CSSLBase.OBJECTIVE_WEIGHTS_UNCERTAINTY_SINGLE ...
         CSSLBase.OBJECTIVE_WEIGHTS_UNCERTAINTY  ...
          ];
end

%% metricOrderInTables

function R = metricOrderInTables()
    R = [MetricProperties.PRBEP     MetricProperties.ACCURACY ...
         MetricProperties.MACRO_ACC MetricProperties.MRR ...
         MetricProperties.MACRO_MRR ];
end
    
end % static methods
    
end % classdef