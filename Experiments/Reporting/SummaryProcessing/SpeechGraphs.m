classdef SpeechGraphs < SummaryReaderBase

%% office
% fileName = 'C:/technion/theses/Tex/SSL/Thesis/Results/thesis_results.txt';
%% home
% fileName = 'E:/technion/theses/Tex/SSL/Thesis/Results/thesis_results.txt';

methods (Static)
    
%% outputDirectory

function R = outputDirectory()
    R = 'E:/technion/theses/Tex/SSL/Thesis/figures/speech_graphs/';
end

%% run

function run(fileName)
    this = SpeechGraphs();
    this.convert(fileName);
end

end % static methods

methods (Access = public)
    
%% doConvert

function doConvert(this)
    this.create();
end

end % overrides

methods (Access = private)
    
%% create

function create(this)
    this.createGraphs();
end

%% plotDifferencesLocalVsGlobal

function plotDifferencesLocalVsGlobal(this, barSource, fileNameSuffix)
    algorithmsOrderInSpeechBars = this.algorithmsOrderInSpeechBars();

    fig = figure;

    LOCAL = 1; GLOBAL = 2;
    bar_position_i = 1;
    for algorithm_ID = algorithmsOrderInSpeechBars
        performanceGain(:,bar_position_i) = ...
            barSource(LOCAL,:,algorithm_ID) - barSource(GLOBAL,:,algorithm_ID); %#ok<AGROW>
        bar_position_i = bar_position_i +1;
    end

    h = bar(performanceGain);

    algorithmColors = AlgorithmProperties.algorithmColors();
    algorithmNames  = AlgorithmProperties.algorithmNames();
%     dbstop in SpeechGraphs.m at 63;
    bar_i = 1;
    for algorithm_ID = algorithmsOrderInSpeechBars
        singleColor = algorithmColors{algorithm_ID};
        set(h(bar_i),'facecolor',singleColor); 
        legendForBars{bar_i} = algorithmNames{algorithm_ID}; %#ok<AGROW>
        bar_i = bar_i + 1;
    end
    
    set(gca,'XGrid','off','YGrid','on');

    fontSize = 22;
    set(gca, 'FontSize', fontSize);

    heightAndWidth = [1024 768] * 0.9;
    figurePosition = [ 1 1 heightAndWidth];
    set(fig, 'Position', figurePosition); % Maximize figure.
%         http://dopplershifted.blogspot.co.il/2008/07/programmatically-saving-matlab-figures.html
%       makes saveas function to not mix up the fonts by resizing the
%       figure
    set(fig, 'PaperPositionMode', 'auto');

    set(gca, 'XTickLabel',{'1%', '5%', '10%', '20%' '30%', '50%'});
    ylabel('Local scaling performance gain');
    xlabel('Precentage of training set used as labeled data');

    legend(legendForBars, 'Location', 'NorthEast');

    fileNamePrefix = 'timit_performance_gain_' ;
    this.saveAndCloseFigure(fig,            SpeechGraphs.outputDirectory(), ...
                            fileNamePrefix, fileNameSuffix);
end

%% createGraphs
    
function createGraphs(this)

    balanced.key = 'balanced';
    balanced.value = {'0'};
    balanced.shouldMatch = 1;

    labeled_init.key = 'labelled init';
    labeled_init.value = {'1'};
    labeled_init.shouldMatch = 1;

    num_iterations.key = 'max iterations';
    num_iterations.value = {'20'};
    num_iterations.shouldMatch = 1;
    
    taco_objective.key = 'TACO objective';
    taco_objective.value = {num2str(CSSLBase.OBJECTIVE_HARMONIC_MEAN)};
    taco_objective.shouldMatch = 1;

    searchProperties = [balanced labeled_init num_iterations taco_objective];

    numLabeledRange = {'11147', '55456', '111133', '221254', '331793','553041'};

    contextSize = 7;

    % accuracy

    optimizeByKey       = 'accuracy';
    presentedKey        = 'avg accuracy';
    yLabel              = 'Frame accuracy';
    fileNameSuffix      = ['accuracy_test_context' num2str(contextSize)];
    yLimits             = [35 65];
    multiplySourceData = 100;
    this.gatherDataAndPlot...
            (   searchProperties, numLabeledRange,...
                optimizeByKey, presentedKey, contextSize, ...
                yLabel, fileNameSuffix, yLimits, ...
                multiplySourceData ...
            );
        
%     % macro averaged accuracy

    optimizeByKey       = 'macroACC';
    presentedKey        = 'avg macro accuracy';
    yLabel              = 'Macro-Averaged Accuracy';
    fileNameSuffix      = ['M_ACC_context' num2str(contextSize)];
    yLimits             = [30 55];
    multiplySourceData  = 100;
    this.gatherDataAndPlot...
            (   searchProperties, numLabeledRange,...
                optimizeByKey, presentedKey, contextSize, ...
                yLabel, fileNameSuffix, yLimits, ...
                multiplySourceData ...
            );

    % levenshtein

    optimizeByKey       = 'levenshtein';
    presentedKey        = 'avg levenshtein';
    yLabel              = 'Phone accuracy';
    fileNameSuffix      = ['levenshtein_test_context' num2str(contextSize)];
    yLimits             = [35 65];
    multiplySourceData  = 1;
    this.gatherDataAndPlot...
            (   searchProperties, numLabeledRange,...
                optimizeByKey, presentedKey, contextSize, ...
                yLabel, fileNameSuffix, yLimits, ...
                multiplySourceData ...
            );
        
    % levenshtein (development)

    optimizeByKey       = 'levenshtein';
    presentedKey        = 'optimized levenshtein';
    yLabel              = 'Phone accuracy';
    fileNameSuffix      = ['levenshtein_development_context' num2str(contextSize)];
    yLimits             = [35 65];
    multiplySourceData  = 1;
    this.gatherDataAndPlot...
            (   searchProperties, numLabeledRange,...
                optimizeByKey, presentedKey, contextSize, ...
                yLabel, fileNameSuffix, yLimits, ...
                multiplySourceData ...
            );

    % M-ACC optimized by accuracy

    optimizeByKey       = 'accuracy';
    presentedKey        = 'avg macro accuracy';
    yLabel              = 'Macro-Averaged Accuracy';
    fileNameSuffix      = ['opt_ACC_report_M_ACC_context' num2str(contextSize)];
    yLimits             = [24 50];
    multiplySourceData  = 100;
    this.gatherDataAndPlot...
            (   searchProperties, numLabeledRange,...
                optimizeByKey, presentedKey, contextSize, ...
                yLabel, fileNameSuffix, yLimits, ...
                multiplySourceData ...
            );
end

%% gatherDataAndPlot

function gatherDataAndPlot...
            (   this, searchProperties, numLabeledRange,...
                optimizeByKey, presentedKey, contextSize, ...
                yLabel, fileNameSuffix, yLimits, ...
                multiplySourceData ...
            )
    barSource = gatherData(this, searchProperties, ...
                                   numLabeledRange, optimizeByKey, presentedKey, contextSize);

    barSource = barSource * multiplySourceData;
    this.plotGraph(barSource, numLabeledRange, ...
                                    yLabel,    yLimits, fileNameSuffix, contextSize);
                                
    this.plotDifferencesLocalVsGlobal(barSource, fileNameSuffix);
end

%% gatherData
%  get the results data 

function barSource = gatherData...
        (this, searchProperties, numLabeledRange, ...
         optimizeByKey, presentedKey, contextSize)
    graph.key = 'graph';
    speechGraphNames = SpeechGraphs.speechGraphNames(contextSize);
    graph.shouldMatch = 1;
    numGraphs = length(speechGraphNames);

    num_labeled.key = 'num labeled';
    num_labeled.shouldMatch = 1;

    optimize_by.key = 'optimize_by';
    optimize_by.shouldMatch = 1;
    optimize_by.value = { optimizeByKey };

    searchProperties = [searchProperties optimize_by];

    numAlgorithms = 4;  
    barSource = zeros(numGraphs, length(numLabeledRange), numAlgorithms);

    for graph_i = 1:numGraphs
        graph.value = speechGraphNames(graph_i);
        Logger.log(['SpeechGraphs::gatherData. '...
                'Searching results for graph ''' graph.value{1} '''']);
        for numLabeled_i=1:length(numLabeledRange)
            num_labeled.value = numLabeledRange(numLabeled_i);
            Logger.log(['SpeechGraphs::gatherData. '...
                'Searching for results for ' num2str(num_labeled.value{1}) ' labeled.']);
            algorithms = this.findAlgorithms([searchProperties num_labeled graph]);
            barSource(graph_i, numLabeled_i , AlgorithmProperties.MAD) = str2num(algorithms.mad( presentedKey ));
            barSource(graph_i, numLabeled_i , AlgorithmProperties.AM)  = str2num(algorithms.am( presentedKey )) ;
            barSource(graph_i, numLabeled_i , AlgorithmProperties.CSSL)= str2num(algorithms.diag( presentedKey )) ;
            barSource(graph_i, numLabeled_i , AlgorithmProperties.QC)  = str2num(algorithms.qc( presentedKey )) ;
        end
    end
end        

%% plotGraph

function plotGraph(this, barSource, numLabeledRange, ...
                         yLabel, yLimits, fileNameSuffix, contextSize)
    % draw
    speechGraphNamesForUser = {'local', 'global'};
    LOCAL = 1; GLOBAL = 2;
    algorithmLineStyle{AlgorithmProperties.MAD,LOCAL}  = 'bs';
    algorithmLineStyle{AlgorithmProperties.MAD,GLOBAL} = 'bs';
    algorithmLineStyle{AlgorithmProperties.AM,LOCAL}   = 'g^';
    algorithmLineStyle{AlgorithmProperties.AM,GLOBAL}  = 'g^';
    algorithmLineStyle{AlgorithmProperties.CSSL,LOCAL} = 'ro';
    algorithmLineStyle{AlgorithmProperties.CSSL,GLOBAL}= 'ro';
    algorithmLineStyle{AlgorithmProperties.QC,GLOBAL}= 'cv';
    algorithmLineStyle{AlgorithmProperties.QC,LOCAL} = 'cv';
    allMarkerEdgeColors{AlgorithmProperties.MAD}  = 'b';
    allMarkerEdgeColors{AlgorithmProperties.AM}   = 'g';
    allMarkerEdgeColors{AlgorithmProperties.CSSL} = 'r';
    allMarkerEdgeColors{AlgorithmProperties.QC} = 'c';
    algorithmNamesForUser = AlgorithmProperties.algorithmNames();

    lineWidth = 4.5;
    markerSize = 13;

    numLabeledRangeAsNumbers = cellfun(@str2num, numLabeledRange);
    %highLimitY = max(barSource(:)) * 1.05;
    %lowLimitY  = min(barSource(:)) * 0.9;

%         this.removeExtraWhiteSpaceMargin();

    speechGraphNames = SpeechGraphs.speechGraphNames(contextSize);
    numGraphs = length(speechGraphNames);

    fileNamePrefix  = 'timit_';
%         dbstop in ExcelToLatexConverter.m at 550;

    algorithmsOrderInSpeechGraphs = this.algorithmsOrderInSpeechGraphs();
    
    for graph_i = 1:numGraphs
        fig = this.create_algorithmCompareFigure(yLimits, yLabel, numLabeledRangeAsNumbers);
        allLegendItems = [];
        graphNameForUser = speechGraphNamesForUser{graph_i};
        Logger.log(['SpeechGraphs::createGraphs. '...
                    'graph_i = ' num2str(graph_i) '. '...
                    'speechGraphNames(graph_i) = ' speechGraphNames{graph_i}]);
        graphStyle = '-';
        for algorithm_ID=algorithmsOrderInSpeechGraphs
            markerEdgeColor = allMarkerEdgeColors{algorithm_ID};
            plot(numLabeledRangeAsNumbers, barSource(graph_i,:,algorithm_ID), ...
                [graphStyle algorithmLineStyle{algorithm_ID,graph_i}]...
                ,'LineWidth',lineWidth...
                ,'MarkerEdgeColor',markerEdgeColor...
                ,'MarkerFaceColor','w'...
                ,'MarkerSize',markerSize);                
            algorithmName = algorithmNamesForUser{algorithm_ID};
            legendItem = [algorithmName];
            allLegendItems = [allLegendItems {legendItem}]; %#ok<AGROW>
        end
        legend(allLegendItems, 'Location', 'SouthEast');
        fileNameSuffixWithGraphName = [fileNameSuffix '_' graphNameForUser];
        this.saveAndCloseFigure(fig, SpeechGraphs.outputDirectory(), ...
                                fileNamePrefix, fileNameSuffixWithGraphName);
    end
end

%% create_algorithmCompareFigure

function fig = create_algorithmCompareFigure(~, yLimits, yLabel, numLabeledRangeAsNumbers)
    fig = figure;
    hold on;

    fontSize = 22;

    %         set(gca,'XScale','log');
    set(gca, 'FontSize', fontSize);
    xlabel('Number of Labeled Examples');

    set(gca,'YLim',yLimits);

    set(gca,'XGrid','off','YGrid','on')
    xlabel('Precentage of training set used as labeled data');
    ylabel(yLabel);

    set(gca,'XLim',[numLabeledRangeAsNumbers(1)-9000 numLabeledRangeAsNumbers(end)+40000]);
    set(gca, 'XTick',numLabeledRangeAsNumbers);
    set(gca, 'XTickLabel',{'1%', '5%', '10%', '20%' '30%', '50%'});

    heightAndWidth = [1024 768] * 0.8;
    figurePosition = [ 1 1 heightAndWidth];
    set(fig, 'Position', figurePosition); % Maximize figure.
%         http://dopplershifted.blogspot.co.il/2008/07/programmatically-saving-matlab-figures.html
%       makes saveas function to not mix up the fonts by resizing the
%       figure
    set(fig, 'PaperPositionMode', 'auto');
end

end % private methods 

methods (Static)
    
%% speechGraphNames

function R = speechGraphNames(contextSize)
    if contextSize > 0
        R = {  ['trainAndTest_cms_white.context' num2str(contextSize) '.k_10.lihi'] ...
               ['trainAndTest_cms_white.context' num2str(contextSize) '.k_10.alex'], ...
            };
    else
        R = {  'trainAndTest_cms_white.k_10.lihi' ...
               'trainAndTest_cms_white.k_10.alex', ...
            };
    end
end

%% algorithmsOrderInSpeechGraphs

function R = algorithmsOrderInSpeechGraphs()
    R = [AlgorithmProperties.CSSL AlgorithmProperties.AM ...
         AlgorithmProperties.QC   AlgorithmProperties.MAD  ];
end

%% algorithmsOrderInSpeechBars

function R = algorithmsOrderInSpeechBars()
    R = [AlgorithmProperties.CSSL AlgorithmProperties.AM ...
         AlgorithmProperties.MAD  AlgorithmProperties.QC];
end

end % static methods

end % classdef