classdef TextMultiDatasetGraphs < TextReporterBase
   
methods (Static)

%% office
% fileName = 'C:/technion/theses/Tex/SSL/Thesis/Results/thesis_results.txt';
%% home
% fileName = 'E:/technion/theses/Tex/SSL/Thesis/Results/thesis_results.txt';

%% main

function main()
    clear classes;clear all;
    fileName = 'E:/technion/theses/Tex/SSL/Thesis/Results/thesis_results.txt';
    % this causes matlab to crash, maybe related to 
    % creating a this of some class within a static function fro that class
    % (?)
%     TextMultiDatasetGraphs.run(fileName);
end

%% run

function run(fileName)
    this = TextMultiDatasetGraphs();
    this.convert(fileName);
end

%% outputDirectory

function R = outputDirectory()
    R = 'E:/technion/theses/Tex/SSL/Thesis/figures/text_multi_datasets_bars/';
end

end % static methods

methods (Access = public)
    
%% doConvert

function doConvert(this)
    this.create();
end

end % overrides

properties (Constant)
    MAD = 1;
    AM = 2; 
    QC = 3;
    CSSL = 4;
end % constant

methods (Access = private)
    
%% create

function create(this)
    results = this.gatherResults_tacoBaseLines();
    this.graphs_byDataset(results);
%     this.graphs_byMetric(results);
%     results = this.gatherResults_tacoVariants();
%     this.graphs_byDataset_tacoVariants(results);
end

%% graphs_byMetric
%  create a bar graph showing results for all 7 NLP data sets
%  with the 3 algorithms MAD/AM/TACO.
%  Used for ECML presentation.

function graphs_byMetric(this, results)
    
    ticksForX        = this.graphNamesForUser();
    metricsRange     = MetricProperties.allMetricsRange;
    metricKeys       = MetricProperties.metricKeys();
    metricShortNames = MetricProperties.metricShortNames();
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
    
    algorithmColors      = AlgorithmProperties.algorithmColors();
    algorithmsOrderInBars= this.algorithmsOrderInBars();
    algorithmNames       = AlgorithmProperties.algorithmNames();
    
    bar_i = 1;
    for algorithm_id = algorithmsOrderInBars
        legendTacoAndBaselines{bar_i} = algorithmNames{algorithm_id}; %#ok<AGROW>
        barColors{bar_i}              = algorithmColors{algorithm_id}; %#ok<AGROW>
        bar_i = bar_i  + 1;
    end

    for graph_i = 1:numGraphs
        algorithmsResults = dataSource{graph_i};
        barSource(graph_i , this.MAD)  = str2num(algorithmsResults.mad ( presentedKey ));
        barSource(graph_i , this.AM)   = str2num(algorithmsResults.am  ( presentedKey )) ;
        barSource(graph_i , this.QC)   = str2num(algorithmsResults.qc  ( presentedKey )) ;
        barSource(graph_i , this.CSSL) = str2num(algorithmsResults.diag( presentedKey )) ;
    end
    barSource = barSource * 100;

    this.plot_barGraph(barSource,            presentedKeyLabelY, ...
                       presentedKeyFileName, yLimits, ticksForX, legendTacoAndBaselines, barColors);
end

%% graphs_byDataset

function graphs_byDataset(this, results)
    
    numGraphs = size(results, 1);
    Logger.log(['TextMultiDatasetGraphs::graphs_byDataset. numGraphs = ' num2str(numGraphs)]);
    
    metricsRange       = [MetricProperties.PRBEP        MetricProperties.ACCURACY   ...
                          MetricProperties.MACRO_ACC    MetricProperties.MRR        ...
                          MetricProperties.MACRO_MRR ];
    metricKeys         = MetricProperties.metricKeys();
    metricShortNames   = MetricProperties.metricShortNames();
    
    nlpGraphIDs          = this.nlpGraphIDs();
    nlpGraphNamerForUser = this.graphNamesForUser();
    graphsYLimits        = this.graphsYLimits();
    algorithmColors      = AlgorithmProperties.algorithmColors();
    algorithmsOrderInBars= this.algorithmsOrderInBars();
    algorithmNames       = AlgorithmProperties.algorithmNames();
    
    metric_i = 1;
    for metric_ID = metricsRange
        ticksForX{metric_i}    = metricShortNames{metric_ID}; %#ok<AGROW>
        metric_i = metric_i + 1;
    end
    
    bar_i = 1;
    for algorithm_id = algorithmsOrderInBars
        legendTacoAndBaselines{bar_i} = algorithmNames{algorithm_id}; %#ok<AGROW>
        barColors{bar_i}              = algorithmColors{algorithm_id}; %#ok<AGROW>
        bar_i = bar_i  + 1;
    end
    
    for graph_i=1:numGraphs
        graph_ID     = nlpGraphIDs(graph_i);
        yLimits      = graphsYLimits{graph_ID};
        graphResults = results(graph_i,:);
        
        metric_i = 1;
        for metric_ID = metricsRange
            algorithmsResults = graphResults{metric_ID};
            metricKey         = metricKeys  {metric_ID};
            stddevKey = this.stddevKey(metricKey);
            barSource(metric_i , this.MAD)  = str2num(algorithmsResults.mad ( metricKey ));
            barSource(metric_i , this.AM)   = str2num(algorithmsResults.am  ( metricKey )) ;
            barSource(metric_i , this.QC)   = str2num(algorithmsResults.qc  ( metricKey )) ;
            barSource(metric_i , this.CSSL) = str2num(algorithmsResults.diag( metricKey )) ;
            stddev   (metric_i , this.MAD)  = str2num(algorithmsResults.mad ( stddevKey ));
            stddev   (metric_i , this.AM)   = str2num(algorithmsResults.am  ( stddevKey ));
            stddev   (metric_i , this.CSSL) = str2num(algorithmsResults.diag( stddevKey ));
            stddev   (metric_i , this.QC)   = str2num(algorithmsResults.qc  ( stddevKey ));
            metric_i = metric_i + 1;
        end
        barSource = barSource * 100;
        stddev    = stddev * 100;
        stddev = (1.96 / sqrt(20)) * stddev ; % 95 confidence intervals.

        presentedKeyFileName = nlpGraphNamerForUser{graph_i};
        presentedKeyFileName( presentedKeyFileName == ' ' ) = '_';
        this.plot_barGraph(barSource, stddev, [], presentedKeyFileName, yLimits, ...
            ticksForX, legendTacoAndBaselines, barColors);
        clear barSource;
    end
end

%% graphs_byDataset_tacoVariants

function graphs_byDataset_tacoVariants(this, results)
    numGraphs = size(results, 1);
    Logger.log(['TextMultiDatasetGraphs::graphs_byDataset_tacoVariants. numGraphs = ' num2str(numGraphs)]);
    
    metricsRange       = TextMultiDatasetGraphs.metricsOrderInPlots();
    metricKeys         = MetricProperties.metricKeys();
    metricShortNames   = MetricProperties.metricShortNames();
    
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
                    str2num(algorithmsResults( metricKey )); %#ok<AGROW,ST2NM>
                algorithm_i = algorithm_i + 1;
            end
            metric_i = metric_i + 1;
        end
        barSource = barSource * 100;

        presentedKeyFileName = nlpGraphNamerForUser{graph_i};
        presentedKeyFileName( presentedKeyFileName == ' ' ) = '_';
        presentedKeyFileName = [presentedKeyFileName '_TACO']; %#ok<AGROW>
        this.plot_barGraph(barSource, [], presentedKeyFileName, yLimits, ...
                                      ticksForX, legendTacoVariants, colorsVariants);
        clear barSource;
    end
end

%% plot_barGraph

function plot_barGraph(this, barSource, stddev, labelY, fileNameSuffix, yLimits, ...
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
%     h = bar(barSource, 'grouped');
    x = repmat((1:size(barSource, 1)).',1,size(barSource, 2));
    [h e] = errorbarbar(x, barSource, stddev);
%         http://dopplershifted.blogspot.co.il/2008/07/programmatically-saving-matlab-figures.html
%       remove extra white space margins around figure
    this.removeExtraWhiteSpaceMargin(gca); %set(gca,'LooseInset',get(gca,'TightInset'))
%         bar(barSource,'hist','rgb');
    numBars = length(colors);
    assert( numBars == size(barSource, 2) );
    for bar_i=1:numBars
        set(h(bar_i),    'facecolor',colors{bar_i}); 
        set(e(bar_i),    'Color',    'k'); 
        set(e(bar_i),    'LineWidth',1.5); 
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

%% metricsOrderInPlots
    
function R = metricsOrderInPlots()
    R = [MetricProperties.PRBEP     MetricProperties.ACCURACY ...
         MetricProperties.MACRO_ACC MetricProperties.MRR ...
         MetricProperties.MACRO_MRR ];
end
    
%% metricYLimits

function R = metricYLimits()
    R{MetricProperties.PRBEP}     = [25 92];
    R{MetricProperties.ACCURACY}  = [25 92];
    R{MetricProperties.MACRO_ACC} = [25 92];
    R{MetricProperties.MRR}       = [50 95];
    R{MetricProperties.MACRO_MRR} = [50 95];
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

%% algorithmsOrderInBars

function R = algorithmsOrderInBars()
    R = [AlgorithmProperties.MAD AlgorithmProperties.AM ...
         AlgorithmProperties.QC  AlgorithmProperties.CSSL];
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
    R{CSSLBase.OBJECTIVE_HARMONIC_MEAN}              = 'Red';
    ...CSSLBase.OBJECTIVE_MULTIPLICATIVE             ...
    R{CSSLBase.OBJECTIVE_HARMONIC_MEAN_SINGLE}       = 'Black';
    R{CSSLBase.OBJECTIVE_WEIGHTS_UNCERTAINTY}        = 'Green';
    R{CSSLBase.OBJECTIVE_WEIGHTS_UNCERTAINTY_SINGLE} = 'Blue';
end

end %static methods

end % classdef