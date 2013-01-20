classdef TextMultiDatasetGraphs < TextReporterBase
   
methods (Static)

%% office
% fileName = 'C:/technion/theses/Tex/SSL/Thesis/Results/thesis_results.txt';

%% main

function main()
    clear classes;clear all;
    fileName = 'C:/technion/theses/Tex/SSL/Thesis/Results/thesis_results.txt';
    TextMultiDatasetGraphs.run(fileName);
end

%% run

function run(fileName)
    this = TextMultiDatasetGraphs();
    this.convert(fileName);
end

%% outputDirectory

function R = outputDirectory()
    R = 'C:/technion/theses/Tex/SSL/Thesis/figures/text_multi_datasets_bars/';
end

end % static methods

methods (Access = public)
    
%% doConvert

function doConvert(this)
    this.create();
end

end % overrides

properties (Constant)
    ACCURACY  = ParamsManager.OPTIMIZE_BY_ACCURACY;
    PRBEP     = ParamsManager.OPTIMIZE_BY_PRBEP;
%     ParamsManager.OPTIMIZE_ALL_1 = 3;
    MRR       = ParamsManager.OPTIMIZE_BY_MRR;
    MACRO_MRR = ParamsManager.OPTIMIZE_BY_MACRO_MRR;
    MACRO_ACC = ParamsManager.OPTIMIZE_BY_MACRO_ACCURACY;
%     ParamsManager.OPTIMIZE_BY_LEVENSHTEIN = 7;

% order of algorithms in bars
    MAD = 1;
    AM = 2; 
    QC = 3;
    CSSL = 4;
end % constant

methods (Access = private)
    
%% create

function create(this)
%     results = this.gatherResults();
%     this.graphs_byDataset(results);
%     this.graphs_byMetric(results);
    results = this.gatherResults_tacoVariants();
    this.graphs_byDataset_tacoVariants(results);
end

%% gatherResults

function results = gatherResults(this)
    balanced.key = 'balanced';
    balanced.value = {'0'};
    balanced.shouldMatch = 1;

    num_labeled.key = 'num labeled';
    numLabeledPerGraph = this.numLabeledPerGraphForTables();
    num_labeled.shouldMatch = 1;

    num_iterations.key = 'max iterations';
    num_iterations.value = {'10'};
    num_iterations.shouldMatch = 1;

    labeled_init.key = 'labelled init';        
    labeled_init.shouldMatch = 1;
    labeled_init.value = {'1'};
    
    taco_objective.key = 'TACO objective';
    taco_objective.value = {num2str(CSSLBase.OBJECTIVE_HARMONIC_MEAN)};
    taco_objective.shouldMatch = 1;

    searchProperties = [taco_objective balanced labeled_init num_iterations];

    graph.key = 'graph';
    nlpGraphNames = this.nlpGraphNames();
    graph.shouldMatch = 1;
    numGraphs = length(nlpGraphNames);

%         for table_i=1:length(searchProperties)
    for graph_i = 1:numGraphs
        graph.value = nlpGraphNames(graph_i);
        num_labeled.value = numLabeledPerGraph(graph_i);

        Logger.log(['TextMultiDatasetGraphs::gatherResults. Looking for result on ''' graph.value{1} ''''...
                    ', num_labeled = ' num2str(num_labeled.value{1})]);

        optimize_by.key = 'optimize_by';
        optimize_by.shouldMatch = 1;

        metricOptimizeByName = this.metricOptimizeByName();
        metricRange          = this.allMetricsRange();
        
        for metric_ID = metricRange
            optimize_by.value = metricOptimizeByName(metric_ID);
            results{graph_i,metric_ID} = ...
                this.findAlgorithms([searchProperties num_labeled graph optimize_by]); %#ok<AGROW>    
        end
    end
end

%% gatherResults_tacoVariants

function results = gatherResults_tacoVariants(this)
    balanced.key = 'balanced';
    balanced.value = {'0'};
    balanced.shouldMatch = 1;

    num_labeled.key = 'num labeled';
    numLabeledPerGraph = this.numLabeledPerGraphForTables();
    num_labeled.shouldMatch = 1;

    num_iterations.key = 'max iterations';
    num_iterations.value = {'10'};
    num_iterations.shouldMatch = 1;

    labeled_init.key = 'labelled init';        
    labeled_init.shouldMatch = 1;
    labeled_init.value = {'1'};
    
    heuristics.key = 'heuristics';
    heuristics.value = {'0'};
    heuristics.shouldMatch = 1;

    algorithm.key = 'Algorithm';
    algorithm.shouldMatch = 1;
    algorithm.value = {CSSLMC.name()};
    
    searchProperties = [balanced labeled_init num_iterations heuristics algorithm];
    
    taco_objective.key = 'TACO objective';
    taco_objective.shouldMatch = 1;

    graph.key = 'graph';
    nlpGraphNames = this.nlpGraphNames();
    graph.shouldMatch = 1;
    numGraphs = length(nlpGraphNames);
    
    TACO_variants_order  = this.TACO_variants_order();
    metricOptimizeByName = this.metricOptimizeByName();
    metricRange          = this.allMetricsRange();

    for graph_i = 1:numGraphs
        graph.value       = nlpGraphNames(graph_i);
        num_labeled.value = numLabeledPerGraph(graph_i);

        Logger.log(['TextMultiDatasetGraphs::gatherResults. Looking for result on ''' graph.value{1} ''''...
                    ', num_labeled = ' num2str(num_labeled.value{1})]);

        optimize_by.key = 'optimize_by';
        optimize_by.shouldMatch = 1;
        
        for metric_ID = metricRange
            optimize_by.value = metricOptimizeByName(metric_ID);
            for TACO_variant_ID = TACO_variants_order
                taco_objective.value = {num2str(TACO_variant_ID)};
                results{graph_i,metric_ID,TACO_variant_ID} = ...
                    this.findEntries([searchProperties num_labeled graph optimize_by taco_objective]); %#ok<AGROW>    
            end
        end
    end
end

%% graphs_byMetric
%  create a bar graph showing results for all 7 NLP data sets
%  with the 3 algorithms MAD/AM/TACO.
%  Used for ECML presentation.

function graphs_byMetric(this, results)
    
    ticksForX        = this.graphNamesForUser();
    metricsRange     = [this.PRBEP this.ACCURACY this.MACRO_ACC this.MRR this.MACRO_MRR ];
    metricKeys       = this.metricKeys();
    metricShortNames = this.metricShortNames();
    metricYLimits    = this.metricYLimits();
    
    for metric_ID = metricsRange
        presentedKey            = metricKeys{metric_ID};
        presentedKeyLabelY      = metricShortNames{metric_ID};
        presentedKeyFileName    = metricShortNames{metric_ID};
        yLimits                 = metricYLimits{metric_ID}; 

        this.plot_byMetric(results(:,metric_ID), ...
                        presentedKey, presentedKeyLabelY, ...
                        presentedKeyFileName, yLimits, ticksForX);
    end
    
end

%% plot_byMetric

function plot_byMetric(this,                 dataSource,          ...
                       presentedKey,         presentedKeyLabelY,  ...
                       presentedKeyFileName, yLimits, ticksForX)
    numGraphs = size(dataSource, 1);
    Logger.log(['TextMultiDatasetGraphs::plot_byMetric. numGraphs = ' num2str(numGraphs)]);

    numAlgorithms = 4;
    barSource = zeros(numGraphs, numAlgorithms);

    for graph_i = 1:numGraphs
        algorithmsResults = dataSource{graph_i};
        barSource(graph_i , this.MAD)  = str2num(algorithmsResults.mad ( presentedKey ));
        barSource(graph_i , this.AM)   = str2num(algorithmsResults.am  ( presentedKey )) ;
        barSource(graph_i , this.QC)   = str2num(algorithmsResults.qc  ( presentedKey )) ;
        barSource(graph_i , this.CSSL) = str2num(algorithmsResults.diag( presentedKey )) ;
    end
    barSource = barSource * 100;

    this.plot_barGraph(barSource,            presentedKeyLabelY, ...
                       presentedKeyFileName, yLimits, ticksForX);
end

%% graphs_byDataset

function graphs_byDataset(this, results)
    
    numGraphs = size(results, 1);
    Logger.log(['TextMultiDatasetGraphs::plot_byMetric. numGraphs = ' num2str(numGraphs)]);
    
    metricsRange       = [this.PRBEP this.ACCURACY this.MACRO_ACC this.MRR this.MACRO_MRR ];
    metricKeys         = this.metricKeys();
    metricShortNames   = this.metricShortNames();
    
    nlpGraphIDs          = this.nlpGraphIDs();
    nlpGraphNamerForUser = this.graphNamesForUser();
    graphsYLimits        = this.graphsYLimits();
    algorithmColors      = this.algorithmColors();
    algorithmsOrder      = this.algorithmsOrder();
    
    metric_i = 1;
    for metric_ID = metricsRange
        ticksForX{metric_i}    = metricShortNames{metric_ID}; %#ok<AGROW>
        metric_i = metric_i + 1;
    end
    
    bar_i = 1;
    for algorithm_id = algorithmsOrder
        barColors{bar_i} = algorithmColors{algorithm_id}; %#ok<AGROW>
        bar_i = bar_i  + 1;
    end
    
    legendTacoAndBaselines = { 'MAD','MP','QC','TACO' };
    
    for graph_i=1:numGraphs
        graph_ID     = nlpGraphIDs(graph_i);
        yLimits      = graphsYLimits{graph_ID};
        graphResults = results(graph_i,:);
        
        metric_i = 1;
        for metric_ID = metricsRange
            algorithmsResults = graphResults{metric_ID};
            metricKey         = metricKeys  {metric_ID};
            barSource(metric_i , this.MAD)  = str2num(algorithmsResults.mad ( metricKey ));
            barSource(metric_i , this.AM)   = str2num(algorithmsResults.am  ( metricKey )) ;
            barSource(metric_i , this.QC)   = str2num(algorithmsResults.qc  ( metricKey )) ;
            barSource(metric_i , this.CSSL) = str2num(algorithmsResults.diag( metricKey )) ;
            metric_i = metric_i + 1;
        end
        barSource = barSource * 100;

        presentedKeyFileName = nlpGraphNamerForUser{graph_i};
        presentedKeyFileName( presentedKeyFileName == ' ' ) = '_';
        this.plot_barGraph(barSource, [], presentedKeyFileName, yLimits, ...
            ticksForX, legendTacoAndBaselines, barColors);
        clear barSource;
    end
end

%% graphs_byDataset_tacoVariants

function graphs_byDataset_tacoVariants(this, results)
    numGraphs = size(results, 1);
    Logger.log(['TextMultiDatasetGraphs::graphs_byDataset_tacoVariants. numGraphs = ' num2str(numGraphs)]);
    
    metricsRange       = [this.PRBEP this.ACCURACY this.MACRO_ACC this.MRR this.MACRO_MRR ];
    metricKeys         = this.metricKeys();
    metricShortNames   = this.metricShortNames();
    
    nlpGraphIDs          = this.nlpGraphIDs();
    nlpGraphNamerForUser = this.graphNamesForUser();
    graphsYLimits        = this.graphsYLimits_tacoVariants();
    TACO_variants_order  = this.TACO_variants_order();
    TACO_variants_names  = this.TACO_variants_names();
    TACO_variants_colors = this.TACO_variants_colors();
    
    metric_i = 1;
    for metric_ID = metricsRange
        ticksForX{metric_i}    = metricShortNames{metric_ID}; %#ok<AGROW>
        metric_i = metric_i + 1;
    end
    
    legend_i = 1;
    for TACO_variant_ID = TACO_variants_order
        legendTacoVariants{legend_i} = TACO_variants_names{TACO_variant_ID}; %#ok<AGROW>
        colorsVariants{legend_i}     = TACO_variants_colors{TACO_variant_ID}; %#ok<AGROW>
        legend_i = legend_i + 1;
    end
    
    for graph_i=1:numGraphs
        graph_ID     = nlpGraphIDs(graph_i);
        yLimits      = graphsYLimits{graph_ID};
        graphResults = results(graph_i,:,:);
        
        metric_i = 1;
        for metric_ID = metricsRange
            metricKey         = metricKeys  {metric_ID};
            algorithm_i = 1;
            for TACO_variant_ID = TACO_variants_order
                algorithmsResults = graphResults{1,metric_ID,TACO_variant_ID};
                algorithmsResults = algorithmsResults{1};
                barSource(metric_i , algorithm_i)  = ...
                    str2num(algorithmsResults( metricKey )); %#ok<ST2NM>
                algorithm_i = algorithm_i + 1;
            end
            metric_i = metric_i + 1;
        end
        barSource = barSource * 100;

        presentedKeyFileName = nlpGraphNamerForUser{graph_i};
        presentedKeyFileName( presentedKeyFileName == ' ' ) = '_';
        presentedKeyFileName = [presentedKeyFileName '_TACO'];
        this.plot_barGraph(barSource, [], presentedKeyFileName, yLimits, ...
                                      ticksForX, legendTacoVariants, colorsVariants);
        clear barSource;
    end
end

%% plot_barGraph

function plot_barGraph(this, barSource, labelY, fileNameSuffix, yLimits, ...
                             ticksForX, legendLabels, colors)
    fig = figure;
    figurePosition = [ 1 1 1280-500 1024-800];
    set(fig, 'Position', figurePosition); % Maximize figure.
%         http://dopplershifted.blogspot.co.il/2008/07/programmatically-saving-matlab-figures.html
%       makes saveas function to not mix up the fonts by resizing the
%       figure
    set(fig, 'PaperPositionMode', 'auto');

%         http://www.mathworks.com/support/solutions/en/data/1-17DC8/
%     h = bar('v6',barSource,'hist');
    h = bar(barSource, 'grouped');
%         http://dopplershifted.blogspot.co.il/2008/07/programmatically-saving-matlab-figures.html
%       remove extra white space margins around figure
    this.removeExtraWhiteSpaceMargin(gca); %set(gca,'LooseInset',get(gca,'TightInset'))
%         bar(barSource,'hist','rgb');
    numBars = length(colors);
    assert( numBars == size(barSource, 2) );
    for bar_i=1:numBars
        set(h(bar_i),    'facecolor',colors{bar_i}); 
    end
    set(gca, 'XTickLabel',ticksForX);
        
    fontSize = 12;
    set(gca, 'FontSize', fontSize);
    
    set(gca,'XGrid','off','YGrid','on');
%     set(gca, 'XTick',[]); % removes XTicks from the plot completly - do
%     not use because removes xticks labels (R2010b)
    set(gca,'YLim',yLimits);
    legend(legendLabels, 'Location', 'SouthEast');
    ylabel(labelY);

    directory = TextMultiDatasetGraphs.outputDirectory();
    this.saveAndCloseFigure(fig, directory, ... 
                            'bars_', fileNameSuffix ...
                            );
end

end % private methods

methods (Static)

%% allMetricsRange

function R = allMetricsRange()
    R = [TextMultiDatasetGraphs.PRBEP     TextMultiDatasetGraphs.ACCURACY ...
         TextMultiDatasetGraphs.MACRO_ACC TextMultiDatasetGraphs.MRR ...
         TextMultiDatasetGraphs.MACRO_MRR ];
end
    
%% metricKeys

function R = metricKeys()
    R{TextMultiDatasetGraphs.PRBEP}     = 'avg PRBEP';
    R{TextMultiDatasetGraphs.ACCURACY}  = 'avg accuracy';
    R{TextMultiDatasetGraphs.MACRO_ACC} = 'avg macro accuracy';
    R{TextMultiDatasetGraphs.MRR}       = 'avg MRR';
    R{TextMultiDatasetGraphs.MACRO_MRR} = 'avg macro MRR';
end

%% metricShortNames

function R = metricShortNames()
    R{TextMultiDatasetGraphs.PRBEP}     = 'PRBEP';
    R{TextMultiDatasetGraphs.ACCURACY}  = 'Accuracy';
    R{TextMultiDatasetGraphs.MACRO_ACC} = 'M-ACC';
    R{TextMultiDatasetGraphs.MRR}       = 'MRR';
    R{TextMultiDatasetGraphs.MACRO_MRR} = 'M-MRR';
end

%% metricOptimizeByName

function R = metricOptimizeByName()
    R{TextMultiDatasetGraphs.PRBEP}     = 'PRBEP';
    R{TextMultiDatasetGraphs.ACCURACY}  = 'accuracy';
    R{TextMultiDatasetGraphs.MACRO_ACC} = 'macroACC';
    R{TextMultiDatasetGraphs.MRR}       = 'MRR';
    R{TextMultiDatasetGraphs.MACRO_MRR} = 'macroMRR';
end

%% metricYLimits

function R = metricYLimits()
    R{TextMultiDatasetGraphs.PRBEP}     = [25 92];
    R{TextMultiDatasetGraphs.ACCURACY}  = [25 92];
    R{TextMultiDatasetGraphs.MACRO_ACC} = [25 92];
    R{TextMultiDatasetGraphs.MRR}       = [50 95];
    R{TextMultiDatasetGraphs.MACRO_MRR} = [50 95];
end

%% graphsYLimits

function R = graphsYLimits()
    R{TextReporterBase.WEB_KB}          = [25 92];
    R{TextReporterBase.NG_20}           = [40 80];
    R{TextReporterBase.ENRON_FARMER}    = [45 80];
    R{TextReporterBase.ENRON_KAMINSKI}  = [25 62];
    R{TextReporterBase.REUTERS}         = [65 95];
    R{TextReporterBase.AMAZON_3}        = [65 95];
    R{TextReporterBase.SENTIMENT_5K}    = [25 70];
end

%% graphsYLimits_tacoVariants

function R = graphsYLimits_tacoVariants()
    R{TextReporterBase.WEB_KB}          = [60 88];
    R{TextReporterBase.NG_20}           = [55 80];
    R{TextReporterBase.ENRON_FARMER}    = [45 80];
    R{TextReporterBase.ENRON_KAMINSKI}  = [35 62];
    R{TextReporterBase.REUTERS}         = [70 95];
    R{TextReporterBase.AMAZON_3}        = [85 97];
    R{TextReporterBase.SENTIMENT_5K}    = [28 68];
end

%% TACO_variants_order

function R = TACO_variants_order()
    R = [CSSLBase.OBJECTIVE_HARMONIC_MEAN        ...CSSLBase.OBJECTIVE_MULTIPLICATIVE             ...
         CSSLBase.OBJECTIVE_HARMONIC_MEAN_SINGLE ...
         CSSLBase.OBJECTIVE_WEIGHTS_UNCERTAINTY  ...
         CSSLBase.OBJECTIVE_WEIGHTS_UNCERTAINTY_SINGLE ...
          ];
end

%% algorithmsOrder

function R = algorithmsOrder()
    R = [TextMultiDatasetGraphs.MAD TextMultiDatasetGraphs.AM ...
         TextMultiDatasetGraphs.QC TextMultiDatasetGraphs.CSSL];
end

%% TACO_variants_names

function R = TACO_variants_names()
    R{CSSLBase.OBJECTIVE_HARMONIC_MEAN} = 'TACO';
    ...CSSLBase.OBJECTIVE_MULTIPLICATIVE             ...
    R{CSSLBase.OBJECTIVE_HARMONIC_MEAN_SINGLE}       = 'TACO-SINGLE';
    R{CSSLBase.OBJECTIVE_WEIGHTS_UNCERTAINTY}        = 'EDGES';
    R{CSSLBase.OBJECTIVE_WEIGHTS_UNCERTAINTY_SINGLE} = 'EDGES-SINGLE';
end

%% TACO_variants_colors

function R = TACO_variants_colors()
    R{CSSLBase.OBJECTIVE_HARMONIC_MEAN} = 'Red';
    ...CSSLBase.OBJECTIVE_MULTIPLICATIVE             ...
    R{CSSLBase.OBJECTIVE_HARMONIC_MEAN_SINGLE}       = 'Black';
    R{CSSLBase.OBJECTIVE_WEIGHTS_UNCERTAINTY}        = 'Green';
    R{CSSLBase.OBJECTIVE_WEIGHTS_UNCERTAINTY_SINGLE} = 'Blue';
end

%% algorithmColors

function R = algorithmColors()
    R{TextMultiDatasetGraphs.MAD} = 'Blue';
    R{TextMultiDatasetGraphs.AM}   = [0 0.543 0];
    R{TextMultiDatasetGraphs.QC}   = 'Cyan';
    R{TextMultiDatasetGraphs.CSSL} = 'Red';
end

end %static methods

end % classdef