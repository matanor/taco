classdef TextMultiDatasetGraphs < TextReporterBase
   
methods (Static)

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
    results = this.gatherResults();
%     this.graphs_byMetric(results);
    this.graphs_byDataset(results);
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

        optimize_by.value = { 'PRBEP' };
        results{graph_i,this.PRBEP} = ...
            this.findAlgorithms([searchProperties num_labeled graph optimize_by]); %#ok<AGROW>

        optimize_by.value = { 'macroACC' };
        results{graph_i,this.MACRO_ACC} = ...
            this.findAlgorithms([searchProperties num_labeled graph optimize_by]); %#ok<AGROW>
        
        optimize_by.value = { 'accuracy' };
        results{graph_i,this.ACCURACY} = ...
                this.findAlgorithms([searchProperties num_labeled graph optimize_by]); %#ok<AGROW>
        
        optimize_by.value = { 'MRR' };
        results{graph_i,this.MRR} = ...
                this.findAlgorithms([searchProperties num_labeled graph optimize_by]); %#ok<AGROW>
        
        optimize_by.value = { 'macroMRR' };
        results{graph_i,this.MACRO_MRR} = ... 
                this.findAlgorithms([searchProperties num_labeled graph optimize_by]); %#ok<AGROW>
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
    
    metricsRange = [this.PRBEP this.ACCURACY this.MACRO_ACC this.MRR this.MACRO_MRR ];
    metricKeys         = this.metricKeys();
    metricShortNames   = this.metricShortNames();
    
    nlpGraphIDs       = this.nlpGraphIDs();
    nlpGraphNamerForUser = this.graphNamesForUser();
    graphsYLimits        = this.graphsYLimits();
    
    metric_i = 1;
    for metric_ID = metricsRange
        ticksForX{metric_i}    = metricShortNames{metric_ID}; %#ok<AGROW>
        metric_i = metric_i + 1;
    end
    
    for graph_i=1:numGraphs
        graph_ID     = nlpGraphIDs(graph_i);
        yLimits = graphsYLimits{graph_ID};
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
        this.plot_barGraph(barSource, [], presentedKeyFileName, yLimits, ticksForX);
        clear barSource;
    end
end

%% plot_barGraph

function plot_barGraph(this, barSource, labelY, fileNameSuffix, yLimits, ticksForX)
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
    set(h(this.MAD),    'facecolor','Blue'); 
    set(h(this.AM),     'facecolor', [0 0.543 0] );
    set(h(this.QC),     'facecolor','Cyan');
    set(h(this.CSSL),   'facecolor','Red'); 
    set(gca, 'XTickLabel',ticksForX);
        
    fontSize = 12;
    set(gca, 'FontSize', fontSize);
    
    set(gca,'XGrid','off','YGrid','on');
%     set(gca, 'XTick',[]); % removes XTicks from the plot completly - do
%     not use because removes xticks labels (R2010b)
    set(gca,'YLim',yLimits);
    legend('MAD','MP','QC','TACO', 'Location', 'SouthEast');
    ylabel(labelY);

    directory = TextMultiDatasetGraphs.outputDirectory();
    this.saveAndCloseFigure(fig, directory, ... 
                            'multiple_graphs_', fileNameSuffix ...
                            );
end

end % private methods

methods (Static)

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

end %static methods

end % classdef