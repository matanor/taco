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
    this.createMultipleDatasetGraphs();
end

end % overrides

methods (Access = private)
    
%% createMultipleDatasetGraphs
%  create a bar graph showing results for all 7 NLP data sets
%  with the 3 algorithms MAD/AM/TACO.
%  Used for ECML presentation.

function createMultipleDatasetGraphs(this)
    
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

    searchProperties = [balanced labeled_init num_iterations];

    graph.key = 'graph';
    nlpGraphNames = this.nlpGraphNames();
    graph.shouldMatch = 1;
    numGraphs = length(nlpGraphNames);

%         for table_i=1:length(searchProperties)
    for graph_i = 1:numGraphs
        graph.value = nlpGraphNames(graph_i);
        num_labeled.value = numLabeledPerGraph(graph_i);

        optimize_by.key = 'optimize_by';
        optimize_by.shouldMatch = 1;

        optimize_by.value = { 'PRBEP' };
        PRBEP{graph_i} = this.findAlgorithms([searchProperties num_labeled graph optimize_by]); %#ok<AGROW>

        optimize_by.value = { 'macroACC' };
        macroAcc{graph_i} = this.findAlgorithms([searchProperties num_labeled graph optimize_by]); %#ok<AGROW>
    end

    presentedKey = 'avg macro accuracy';
    presentedKeyLabelY = 'macro-averaged accuracy (M-ACC)';
    presentedKeyFileName = 'M-ACC';
    yLimits = [25 92];

    this.plotMultipleDatasetsGraph(macroAcc, numGraphs, ...
                        presentedKey, presentedKeyLabelY, ...
                        presentedKeyFileName, yLimits);

    presentedKey = 'avg PRBEP';
    presentedKeyLabelY = 'macro-averaged PRBEP';
    presentedKeyFileName = 'PRBEP';
%         yLimits = [25 100];

    this.plotMultipleDatasetsGraph(PRBEP, numGraphs, ...
                        presentedKey, presentedKeyLabelY, ...
                        presentedKeyFileName, yLimits);
end

%% plotMultipleDatasetsGraph

function plotMultipleDatasetsGraph(this, dataSource, numGraphs, ...
                                         presentedKey, presentedKeyLabelY, ...
                                         presentedKeyFileName, yLimits)
    numAlgorithms = 3;
    barSource = zeros(numGraphs, numAlgorithms);
    fontSize = 25;

    MAD = 1;        AM = 2; CSSL = 3;
    for graph_i = 1:numGraphs
        algorithmsResults = dataSource{graph_i};
        barSource(graph_i , MAD)  = str2num(algorithmsResults.mad ( presentedKey ));
        barSource(graph_i , AM)   = str2num(algorithmsResults.am  ( presentedKey )) ;
        barSource(graph_i , CSSL) = str2num(algorithmsResults.diag( presentedKey )) ;
    end
    barSource = barSource * 100;

    fig = figure;
    figurePosition = [ 1 1 1280 1024-300];
    set(fig, 'Position', figurePosition); % Maximize figure.
%         http://dopplershifted.blogspot.co.il/2008/07/programmatically-saving-matlab-figures.html
%       makes saveas function to not mix up the fonts by resizing the
%       figure
    set(fig, 'PaperPositionMode', 'auto');

%         http://www.mathworks.com/support/solutions/en/data/1-17DC8/
    h = bar('v6',barSource,'hist');
%         http://dopplershifted.blogspot.co.il/2008/07/programmatically-saving-matlab-figures.html
%       remove extra white space margins around figure
    set(gca,'LooseInset',get(gca,'TightInset'))
%         bar(barSource,'hist','rgb');
    set(h(1),'facecolor','b'); 
    set(h(2),'facecolor','g');
    set(h(3),'facecolor','r'); 
    set(gca, 'XTickLabel',this.graphNamesForUser());
    set(gca, 'FontSize', fontSize);
    set(gca,'XGrid','off','YGrid','on');
%     set(gca, 'XTick',[]); % removes XTicks from the plot completly - do
%     not use because removes xticks labels (R2010b)
    set(gca,'YLim',yLimits);
    legend('MAD','MP','TACO', 'Location', 'NorthWest');
    ylabel(presentedKeyLabelY);

    directory = TextMultiDatasetGraphs.outputDirectory();
    this.saveAndCloseFigure(fig, directory, ... 
                            'multiple_graphs_', presentedKeyFileName ...
                            );
end

end % private methods

end % classdef