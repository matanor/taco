classdef SpeechGraphs < SummaryReaderBase

%% createGraphs_eilat_2012

methods (Access = private)

%% plotDifferencesLocalVsGlobal_eilat_2012

function plotDifferencesLocalVsGlobal_eilat_2012(this, barSource)
    [MAD AM CSSL] = SpeechGraphs.graphIDs();

    fig = figure;

    LOCAL = 1; GLOBAL = 2;
    bar_position_i = 1;
    for algorithm_i = [CSSL AM MAD ]
        performanceGain(:,bar_position_i) = ...
            barSource(LOCAL,:,algorithm_i) - barSource(GLOBAL,:,algorithm_i); %#ok<AGROW>
        bar_position_i = bar_position_i +1;
    end

    h = bar(performanceGain);

    set(h(1),'facecolor','r'); 
    set(h(2),'facecolor','g');
    set(h(3),'facecolor','b'); 
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

    legend({'TACO', 'MP', 'MAD'}, 'Location', 'NorthEast');

    directory = 'E:/technion/theses/Tex/SSL/2012_11_IEEE_eilat_TACO_speech/figures/';
    fileName = 'local_scaling_performance_gain' ;
    fileFullPath = [ directory fileName '.pdf'];
    saveas(fig, fileFullPath ); 
    Logger.log(['ExcelToLatexConverter::plotDifferencesLocalVsGlobal_eilat_2012. '...
                'Saving figure to ''' fileFullPath '''']);
    close(fig);

end


%% createGraphs_eilat_2012
    
function createGraphs_eilat_2012(this)

    balanced.key = 'balanced';
    balanced.value = {'0'};
    balanced.shouldMatch = 1;

    labeled_init.key = 'labelled init';
    labeled_init.value = {'1'};
    labeled_init.shouldMatch = 1;

    num_iterations.key = 'max iterations';
    num_iterations.value = {'20'};
    num_iterations.shouldMatch = 1;

    searchProperties = [balanced labeled_init num_iterations];

    numLabeledRange = {'11147', '55456', '111133', '221254', '331793','553041'};

    contextSize = 7;

    % accuracy

    optimizeByKey       = 'accuracy';
    presentedKey        = 'avg accuracy';
    yLabel              = 'Frame accuracy';
    fileNameSuffix      = ['accuracy_context' num2str(contextSize)];
    yLimits             = [35 65];
    multiplySourceData = 100;
    this.getDataAndPlot_eilat_2012...
            (   searchProperties, numLabeledRange,...
                optimizeByKey, presentedKey, contextSize, ...
                yLabel, fileNameSuffix, yLimits, ...
                multiplySourceData ...
            );

    % macro averaged accuracy

    optimizeByKey       = 'macroACC';
    presentedKey        = 'avg macro accuracy';
    yLabel              = 'Macro-Averaged Accuracy';
    fileNameSuffix      = ['M_ACC_context' num2str(contextSize)];
    yLimits             = [30 55];
    multiplySourceData  = 100;
    this.getDataAndPlot_eilat_2012...
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
    this.getDataAndPlot_eilat_2012...
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
    this.getDataAndPlot_eilat_2012...
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
    this.getDataAndPlot_eilat_2012...
            (   searchProperties, numLabeledRange,...
                optimizeByKey, presentedKey, contextSize, ...
                yLabel, fileNameSuffix, yLimits, ...
                multiplySourceData ...
            );
end

%% getDataAndPlot_eilat_2012

function getDataAndPlot_eilat_2012...
            (   this, searchProperties, numLabeledRange,...
                optimizeByKey, presentedKey, contextSize, ...
                yLabel, fileNameSuffix, yLimits, ...
                multiplySourceData ...
            )
    barSource = getData_eilat_2012(this, searchProperties, ...
                                   numLabeledRange, optimizeByKey, presentedKey, contextSize);

    barSource = barSource * multiplySourceData;
    this.plotSingleGraph_eilat_2012(barSource, numLabeledRange, ...
                                    yLabel,    yLimits, fileNameSuffix, contextSize);
end

%% getData_eilat_2012
%  get the results data 

function barSource = getData_eilat_2012...
        (this, searchProperties, numLabeledRange, ...
         optimizeByKey, presentedKey, contextSize)
    graph.key = 'graph';
    speechGraphNames = SpeechGraphs.speechGraphNames(contextSize);
    graph.shouldMatch = 1;
    numGraphs = length(speechGraphNames);

    [MAD AM CSSL] = SpeechGraphs.graphIDs();
    num_labeled.key = 'num labeled';
    num_labeled.shouldMatch = 1;

    optimize_by.key = 'optimize_by';
    optimize_by.shouldMatch = 1;
    optimize_by.value = { optimizeByKey };

    searchProperties = [searchProperties optimize_by];

    numAlgorithms = 3;  
    barSource = zeros(numGraphs, length(numLabeledRange), numAlgorithms);

    for graph_i = 1:numGraphs
        graph.value = speechGraphNames(graph_i);
        for numLabeled_i=1:length(numLabeledRange)
            num_labeled.value = numLabeledRange(numLabeled_i);
            Logger.log(['ExcelToLatexConverter::getData_eilat_2012. '...
                'Searching for results for ' num2str(num_labeled.value{1}) ' labeled.']);
            algorithms = this.findAlgorithms([searchProperties num_labeled graph]);
            barSource(graph_i, numLabeled_i , MAD) = str2num(algorithms.mad( presentedKey ));
            barSource(graph_i, numLabeled_i , AM)  = str2num(algorithms.am( presentedKey )) ;
            barSource(graph_i, numLabeled_i , CSSL)= str2num(algorithms.diag( presentedKey )) ;
        end
    end
end        

%% plotSingleGraph_eilat_2012

function plotSingleGraph_eilat_2012(this, barSource, numLabeledRange, ...
                                    yLabel, yLimits, fileNameSuffix, contextSize)
    [MAD AM CSSL] = SpeechGraphs.graphIDs();

    % draw

%         graphStyleRange = {'-',':'};
    speechGraphNamesForUser = {'local', 'global'};
    LOCAL = 1; GLOBAL = 2;
    algorithmLineStyle{MAD,LOCAL}  = 'bs';
    algorithmLineStyle{MAD,GLOBAL} = 'bs';
    algorithmLineStyle{AM,LOCAL}   = 'g^';
    algorithmLineStyle{AM,GLOBAL}  = 'g^';
    algorithmLineStyle{CSSL,LOCAL} = 'ro';
    algorithmLineStyle{CSSL,GLOBAL}= 'ro';
    allMarkerEdgeColors{MAD} = 'b';
    allMarkerEdgeColors{AM} = 'g';
    allMarkerEdgeColors{CSSL} = 'r';
    algorithmNamesForUser = {'MAD', 'MP', 'TACO'};

    lineWidth = 4.5;
    markerSize = 13;

    numLabeledRangeAsNumbers = cellfun(@str2num, numLabeledRange);
    %highLimitY = max(barSource(:)) * 1.05;
    %lowLimitY  = min(barSource(:)) * 0.9;

%         this.removeExtraWhiteSpaceMargin();

    speechGraphNames = SpecchGraphs.speechGraphNames(contextSize);
    numGraphs = length(speechGraphNames);

    outputDirectory = 'E:/technion/theses/Tex/SSL/2012_11_IEEE_eilat_TACO_speech/figures/';
    fileNamePrefix  = 'timit_compare_algorithms_';
%         dbstop in ExcelToLatexConverter.m at 550;

    for graph_i = 1:numGraphs
        fig = this.createFigure_algorithmCompare_eilat_2012(yLimits, yLabel, numLabeledRangeAsNumbers);
        allLegendItems = [];
        graphNameForUser = speechGraphNamesForUser{graph_i};
        Logger.log(['ExcelToLatexConverter::createGraphs_eilat_2012. '...
                    'graph_i = ' num2str(graph_i) '. '...
                    'speechGraphNames(graph_i) = ' speechGraphNames{graph_i}]);
%             graphStyle = graphStyleRange{graph_i};
        graphStyle = '-';
        for algorithm_i=[CSSL AM MAD]
            markerEdgeColor = allMarkerEdgeColors{algorithm_i};
            plot(numLabeledRangeAsNumbers, barSource(graph_i,:,algorithm_i), ...
                [graphStyle algorithmLineStyle{algorithm_i,graph_i}]...
                ,'LineWidth',lineWidth...
                ,'MarkerEdgeColor',markerEdgeColor...
                ,'MarkerFaceColor','w'...
                ,'MarkerSize',markerSize);                
            algorithmName = algorithmNamesForUser{algorithm_i};
%                 legendItem = [algorithmName ' / ' graphNameForUser ' scaling'];
            legendItem = [algorithmName];
            allLegendItems = [allLegendItems {legendItem}]; %#ok<AGROW>
        end
        legend(allLegendItems, 'Location', 'SouthEast');
        fileNameSuffixWithGraphName = [fileNameSuffix '_' graphNameForUser];
        this.saveAndCloseFigure(fig, outputDirectory, fileNamePrefix, fileNameSuffixWithGraphName);
    end
end

%% createFigure_algorithmCompare_eilat_2012

function fig = createFigure_algorithmCompare_eilat_2012(~, yLimits, yLabel, numLabeledRangeAsNumbers)
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

function R = speechGraphNames(~, contextSize)
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


%% graphIDs
    
function [MAD AM CSSL] = graphIDs()
    MAD = 1;        AM = 2; CSSL = 3;
end
    
end % static methods

end % classdef