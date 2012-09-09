classdef ExcelToLatexConverter < TextReader
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

%% file name on office desktop
% For paper 2012_TACO_in_ECML
% fileName = 'C:/technion/theses/Experiments/results/2012_04_22 For Paper Graph based transduction with Confidence/BigTableSummary.txt';    
% For paper 2012 TACO on speech EILAT IEEEI
% fileName = 'C:/technion/theses/Experiments/results/2012_09_02_01 Speech Results Summary For Paper/BigTableSummary.txt'
% fileName = 'e:/technion/theses/Experiments/results/2012_09_02_01 Speech Results Summary For Paper/BigTableSummary.txt'

%% properties
    
properties
    m_allResults;
    m_resultMaps;
    m_header;
    m_numResults;
end

%% methods

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
        this.createGraphs_eilat_2012();
        %this.createGraphs_ecml_2012();
        %this.createTables();
        %this.createWebKBTable();
%         this.createMultipleDatasetGraphs();
        this.clearAll();
    end
    
    %% init
    
    function init(this)
        init@TextReader(this);
        this.clearAll();
    end
    
    %% createWebKBTable
     
    function createWebKBTable(this)
        opt_PRBEP = [0.85428     0.60815     0.46296     0.78437;
                     0.8101      0.59947     0.42628     0.74478;
                     0.85479     0.58924     0.41442     0.76182].';
        opt_M_ACC = [0.85448     0.60914     0.46015     0.78547;
                     0.79452      0.5811     0.39114     0.67955;
                     0.78056     0.53631     0.31394     0.56355].';
        opt_PRBEP = opt_PRBEP * 100;
        opt_M_ACC = opt_M_ACC * 100;
%         mean_PRBEP = mean(opt_PRBEP);
        CSSL = 3;
        AM = 2;
        MAD = 1;
        
        outputFileName = [this.inputFileName() '.webkb.tex'];
        outputFile  = fopen(outputFileName, 'a+');
        
        fprintf(outputFile, '/\begin{table}\n');
        fprintf(outputFile, '\\centering\n');
        fprintf(outputFile, '\\begin{tabular}{ | c | c | c | c | c | }\n');
        fprintf(outputFile, '\\hline\n');
        fprintf(outputFile, '\\multicolumn{2}{|c||}{}  & MAD & AM & \\algorithmName } \\\\\n');
        fprintf(outputFile, '\\hline\n');
        
        lineFormat = ['~%s~    & ~%s~  & ~%s~ & ~%s~ & ~%s~ & ~%s~ \\\\ \\hline\n'];
        
        COURSE = 1; FACULTY = 2; PROJECT = 3; STUDENT = 4;
        
        sourceTable = opt_PRBEP;
        this.printWebKBLine(outputFile, lineFormat, [], 'course', sourceTable(COURSE,:));
        this.printWebKBLine(outputFile, lineFormat, [], 'faculty', sourceTable(FACULTY,:));
        this.printWebKBLine(outputFile, lineFormat, [], 'project', sourceTable(PROJECT,:));
        this.printWebKBLine(outputFile, lineFormat, [], 'student', sourceTable(STUDENT,:));
        
        fprintf(outputFile, '\\hline\n');
        fprintf(outputFile, '\\end{tabular}\n');

        fprintf(outputFile, '\\vspace{0.5cm}\n');
                   
        fprintf(outputFile, '\\caption{\\webkbTableCaption}\n');
        fprintf(outputFile, '\\label{tab:table_webkb_PRBEP}\n' );
        fprintf(outputFile, '\\end{table}\n');
        
        fclose(outputFile);
    end
    
    %% printWebKBLine
    
    function printWebKBLine(~, outputFile, firstColumn, className, numeriaclValues)
        CSSL = 3;
        AM = 2;
        MAD = 1;
        
        [~, maxPosition] = max(numeriaclValues);
        stringValues = cellstr(num2str(numeriaclValues, '%.1f'));
        stringValues{maxPosition} = ['\textbf{' stringValues{maxPosition} '}'];
        fprintf(outputFile, lineFormat, firstColumn, className, ...
                stringValues{MAD},stringValues{AM}, stringValues{MAD});
    end
    
    %% clearAll
    
    function clearAll(this)
        this.m_allResults = [];
        this.m_numResults = 0;
        this.m_resultMaps = [];
        this.m_header = [];
    end
    
    %% speechGraphNames
    
    function R = speechGraphNames(~)
        R = {  'trainAndTest_cms_white.context7.k_10.lihi' ...
               'trainAndTest_cms_white.context7.k_10.alex', ...
             };
    end
    
    %% nlpGraphNames
    
    function R = nlpGraphNames(~)
        R = {  'webkb_constructed' , ...
               'twentyNG_4715', ...
               'sentiment_5k' ...
               'reuters_4_topics.tfidf.graph', ...
               'farmer-d.tfidf.graph', ...
               'kaminski-v.tfidf.graph', ...
               'books_dvd_music.tfidf.graph' ...
             };
    end
    
    function R = graphNamesForUser(~)
        R = {  'WebKB' , ...
               '20 News', ...
               'Sentiment' ...
               'Reuters', ...
               'Enron A', ...
               'Enron B', ...
               'Amazon3' ...
             };
    end
    
    %% numLabeledPerGraphForTables
    
    function R = numLabeledPerGraphForTables(~)
        R = { '48' , ...
              '105', ...
              '500' ...
              '48', ...
              '48', ...
              '48', ...
              '35' ...
            };
    end
    
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
        set(gca, 'XTick',[]); % removes XTicks from the plot completly
        set(gca,'YLim',yLimits);
        legend('MAD','AM','TACO', 'Location', 'NorthWest');
        ylabel(presentedKeyLabelY);

        directory = 'E:/technion/theses/Tex/SSL/GraphSSL_Confidence_Paper/ECML_Presentation/';
        fileName = ['multiple_graphs_' presentedKeyFileName] ;
        fileFullPath = [ directory fileName '.jpg'];
        Logger.log(['Saving image to file ' fileFullPath]);
        saveas(fig, fileFullPath ); 
        close(fig);
    end
    
    %% removeExtraWhiteSpaceMargin
    %  http://dopplershifted.blogspot.co.il/2008/07/programmatically-saving-matlab-figures.html
    %  remove extra white space margins around figure
    
    function removeExtraWhiteSpaceMargin(~)
        set(gca,'LooseInset',get(gca,'TightInset'))
    end
    
    %% graphIDs
    
    function [MAD AM CSSL] = graphIDs(~)
        MAD = 1;        AM = 2; CSSL = 3;
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

        numLabeledRange = {'11147', '55456', '111133', '221254'};

        % accuracy

        optimizeByKey = 'accuracy';
        presentedKey = 'avg accuracy';
        
        barSource = getData_eilat_2012(this, searchProperties, ...
                                       numLabeledRange, optimizeByKey, presentedKey);
        
        yLabel = 'Accuracy';
        fileNameSuffix = 'accuracy';
        yLimits = [35 62];
        barSource = barSource * 100;
        this.plotSingleGraph_eilat_2012(barSource, numLabeledRange, ...
                                        yLabel,    yLimits, fileNameSuffix);
             
        % macro averaged accuracy
        
        optimizeByKey = 'macroACC';
        presentedKey = 'avg macro accuracy';
        
        barSource = getData_eilat_2012(this, searchProperties, ...
                                       numLabeledRange, optimizeByKey, presentedKey);
                                   
        yLabel = 'Macro-Averaged Accuracy';
        fileNameSuffix = 'M_ACC';
        yLimits = [30 50];
        barSource = barSource * 100;
        this.plotSingleGraph_eilat_2012(barSource, numLabeledRange, ...
                                        yLabel,    yLimits, fileNameSuffix);
      
        % levenshtein
        
        optimizeByKey = 'levenshtein';
        presentedKey = 'avg levenshtein';
        
        barSource = getData_eilat_2012(this, searchProperties, ...
                                       numLabeledRange, optimizeByKey, presentedKey);
        
        yLabel = 'Levenshtein';
        fileNameSuffix = 'levenshtein';
        yLimits = [35 62];
        this.plotSingleGraph_eilat_2012(barSource, numLabeledRange, ...
                                        yLabel,    yLimits, fileNameSuffix);
                                    
        % M-ACC optimized by accuracy
        
        optimizeByKey = 'accuracy';
        presentedKey = 'avg macro accuracy';
        
        barSource = getData_eilat_2012(this, searchProperties, ...
                                       numLabeledRange, optimizeByKey, presentedKey);
        
        yLabel = 'Macro-Averaged Accuracy';
        fileNameSuffix = 'opt_ACC_report_M_ACC';
        yLimits = [24 50];
        barSource = barSource * 100;
        this.plotSingleGraph_eilat_2012(barSource, numLabeledRange, ...
                                        yLabel,    yLimits, fileNameSuffix);

    end
    
    %% getData_eilat_2012
    %  get the results data 
    
    function R = getData_eilat_2012(this,            searchProperties, ...
                                    numLabeledRange, optimizeByKey, ...
                                    presentedKey)
        graph.key = 'graph';
        speechGraphNames = this.speechGraphNames();
        graph.shouldMatch = 1;
        numGraphs = length(speechGraphNames);
        
        [MAD AM CSSL] = this.graphIDs();
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
                algorithms = this.findAlgorithms([searchProperties num_labeled graph]);
                barSource(graph_i, numLabeled_i , MAD) = str2num(algorithms.mad( presentedKey ));
                barSource(graph_i, numLabeled_i , AM)  = str2num(algorithms.am( presentedKey )) ;
                barSource(graph_i, numLabeled_i , CSSL)= str2num(algorithms.diag( presentedKey )) ;
            end
        end
        
        R = barSource;
    end        
    
    %% plotSingleGraph_eilat_2012
    
    function plotSingleGraph_eilat_2012(this, barSource, numLabeledRange, ...
                                           yLabel, yLimits, fileNameSuffix)
        [MAD AM CSSL] = this.graphIDs();
        
        % draw
        
        fig = figure;
        hold on;
        graphStyleRange = {'-',':'};
        speechGraphNamesForUser = {'local', 'global'};
        LOCAL = 1; GLOBAL = 2;
        algorithmLineStyle{MAD,LOCAL}  = 'bs';
        algorithmLineStyle{MAD,GLOBAL} = 'bd';
        algorithmLineStyle{AM,LOCAL}   = 'g^';
        algorithmLineStyle{AM,GLOBAL}  = 'g>';
        algorithmLineStyle{CSSL,LOCAL} = 'ro';
        algorithmLineStyle{CSSL,GLOBAL}= 'rv';
        allMarkerEdgeColors{MAD} = 'b';
        allMarkerEdgeColors{AM} = 'g';
        allMarkerEdgeColors{CSSL} = 'r';
        algorithmNamesForUser = {'MAD', 'MP', 'TACO'};
        allLegendItems = [];
        
        lineWidth = 4.5;
        markerSize = 13;
        fontSize = 22;
%         set(gca,'XScale','log');
        set(gca, 'FontSize', fontSize);
        xlabel('Number of Labeled Examples');
        %highLimitY = max(barSource(:)) * 1.05;
        %lowLimitY  = min(barSource(:)) * 0.9;
        
        set(gca,'YLim',yLimits);
        
        set(gca,'XGrid','off','YGrid','on')
        xlabel('Precentage of training set used as labeled data');
        ylabel(yLabel);
                
        numLabeledRangeAsNumbers = cellfun(@str2num, numLabeledRange);
        set(gca,'XLim',[numLabeledRangeAsNumbers(1)-6000 numLabeledRangeAsNumbers(end)+15000]);
        set(gca, 'XTick',numLabeledRangeAsNumbers);
        set(gca, 'XTickLabel',{'1%', '5%', '10%', '20%'});
        
        heightAndWidth = [1024 768] * 0.9;
        figurePosition = [ 1 1 heightAndWidth];
        set(fig, 'Position', figurePosition); % Maximize figure.
%         http://dopplershifted.blogspot.co.il/2008/07/programmatically-saving-matlab-figures.html
%       makes saveas function to not mix up the fonts by resizing the
%       figure
        set(fig, 'PaperPositionMode', 'auto');

%         this.removeExtraWhiteSpaceMargin();

        speechGraphNames = this.speechGraphNames();
         
        numGraphs = length(speechGraphNames);
        for algorithm_i=[CSSL AM MAD]
            for graph_i = 1:numGraphs
                Logger.log(['ExcelToLatexConverter::createGraphs_eilat_2012. '...
                            'graph_i = ' num2str(graph_i) '. '...
                            'speechGraphNames(graph_i) = ' speechGraphNames{graph_i}]);
                graphStyle = graphStyleRange{graph_i};
                markerEdgeColor = allMarkerEdgeColors{algorithm_i};
                plot(numLabeledRangeAsNumbers, barSource(graph_i,:,algorithm_i), ...
                    [graphStyle algorithmLineStyle{algorithm_i,graph_i}]...
                    ,'LineWidth',lineWidth...
                    ,'MarkerEdgeColor',markerEdgeColor...
                    ,'MarkerFaceColor','w'...
                    ,'MarkerSize',markerSize);
                graphNameForUser = speechGraphNamesForUser{graph_i};
                algorithmName = algorithmNamesForUser{algorithm_i};
                legendItem = [algorithmName ' / ' graphNameForUser ' scaling'];
                allLegendItems = [allLegendItems {legendItem}]; %#ok<AGROW>
            end
        end
        legend(allLegendItems, 'Location', 'SouthEast');
%         this.shrinkLegend(h,0.9);

        directory = 'E:/technion/theses/Tex/SSL/2012_IEEE_eilat_TACO_speech/figures/';
        fileName = ['compare_algorithms_' fileNameSuffix] ;
%         fileFullPath = [ directory fileName '.jpg'];
%         saveas(fig, fileFullPath ); 
        fileFullPath = [ directory fileName '.pdf'];
        saveas(fig, fileFullPath ); 
        Logger.log(['ExcelToLatexConverter::createGraphs_eilat_2012. '...
                    'Saving figure to ''' fileFullPath '''']);
        close(fig);
    end
    

    %% SHRINKLEGEND - Changes LEGEND fontsize and axes position
    %
    %Syntax: shrinkLegend(hL, shrinkFact)
    %
    %Inputs: 
    % hL Legend axes handle
    % shrinkFact Factor by which to shrink the legend.
    % Default is 0.8
    % 
    %Example: %Make fontsize and legend axes twice bigger
    % hL=legend(......);
    % shrinklegend(hL,2); 
    %
    %Authors: Jim Phillips and Denis Gilbert, 03-Dec-1999

%     function [] = shrinkLegend (~, hL, shrinkFact)
%     
%         if ~exist('shrinkFact','var'), shrinkFact = 0.8; end
% 
%         p = get(hL, 'position');
%         p(3) = p(3)*shrinkFact;
%         p(4) = p(4)*shrinkFact;
%         set(hL,'position', p)
%         ht = findobj( get(hL,'children'), 'type', 'text');
% %        set(ht, 'FontSize', get(ht,'FontSize')*shrinkFact)
% %        set(gcf,'Resizefcn','')
%     end
    
    %% createGraphs_ecml_2012
    %  create graphs for WebKB data set with different amounts of
    %  supervision. Graphs report PRBEP and M-ACC, each tuned by 
    %  both PRBEP and M-ACC, for a total of 4 graphs.
    
    function createGraphs_ecml_2012(this)
        graph.key = 'graph';
        graph.value = {'webkb_constructed'};
        graph.shouldMatch = 1;
        
        balanced.key = 'balanced';
        balanced.value = {'0'};
        balanced.shouldMatch = 1;
        
        labeled_init.key = 'labelled init';
        labeled_init.value = {'1'};
        labeled_init.shouldMatch = 1;
        
        PRBEP_limit.low = 48;
        PRBEP_limit.high = 82;
        
        M_ACC_limit.low = 20;
        M_ACC_limit.high = 82;
        
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
        % 1 PRBEP by PRBEP %%%%%%%%%%%%%%%%%%
        
        this.createSingleFigure(figuresFileID, [searchProperties optimize_by], presentedKey, ...
            presentedKeyFileName, presentedKeyLabelY, optimizeByForFileName, PRBEP_limit.low, PRBEP_limit.high);

        fprintf(figuresFileID,'\\quad\n');
                
        presentedKey = 'avg macro accuracy';
        presentedKeyFileName = 'M-ACC';
        presentedKeyLabelY = 'macro-averaged accuracy (M-ACC)';
        
        % 2 M-ACC by PRBEP %%%%%%%%%%%%%%%%%%
        
        this.createSingleFigure(figuresFileID, [searchProperties optimize_by], presentedKey, ...
            presentedKeyFileName, presentedKeyLabelY, optimizeByForFileName,...
            M_ACC_limit.low, M_ACC_limit.high);

        fprintf(figuresFileID,'}\\\\\n');
        fprintf(figuresFileID,'\\mbox{\n');

        optimizeByForFileName = 'opt_M-ACC';
        optimize_by.value = { 'macroACC' };

        presentedKey = 'avg macro accuracy';
        presentedKeyFileName = 'M-ACC';
        presentedKeyLabelY = 'macro-averaged accuracy (M-ACC)';

        % 3 M-ACC by M-ACC %%%%%%%%%%%%%%%%%%
                
        this.createSingleFigure(figuresFileID, [searchProperties optimize_by], presentedKey, ...
            presentedKeyFileName, presentedKeyLabelY, optimizeByForFileName,...
             M_ACC_limit.low, M_ACC_limit.high);
        
        fprintf(figuresFileID,'\\quad\n');

        presentedKey = 'avg PRBEP';
        presentedKeyFileName = 'PRBEP';
        presentedKeyLabelY = 'macro-averaged PRBEP';

        % 4 PRBEP by M-ACC %%%%%%%%%%%%%%%%%%
        
        this.createSingleFigure(figuresFileID, [searchProperties optimize_by], presentedKey, ...
            presentedKeyFileName, presentedKeyLabelY, optimizeByForFileName, PRBEP_limit.low, PRBEP_limit.high);
        
        fprintf(figuresFileID,'}\n');

        fprintf(figuresFileID,'\\caption{\\numLabelsCompareCaption}\n');
        fprintf(figuresFileID,'\\label{fig:webkb_num_labeled_comare}\n');
        fprintf(figuresFileID,'\\vspace{-15pt}\n');
        fprintf(figuresFileID,'\\end{figure}\n');

        fclose(figuresFileID);
    end
       
    %% createSingleFigure
    
    function createSingleFigure(this, figuresFileID, searchProperties, presentedKey, ...
                                presentedKeyFileName, presentedKeyLabelY,...
                                optimizeByForFileName, lowLimitY, highLimitY)
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
        barSource = barSource * 100 ;
        stddev = stddev * 100;
        stddev = (1.96 / sqrt(20)) * stddev ;
        %stddev = stddev / 2;
        grid on;
        numLabeledRangeMatrix = str2num(char(numLabeledRange));
        hold on;
        algorithm = MAD;
        lineWidth = 4.5;
        markerSize = 13;
        errorbar(numLabeledRangeMatrix,barSource(:,algorithm), stddev(:,algorithm),...
                '-bs','LineWidth',lineWidth,...
                'MarkerEdgeColor','b',...
                'MarkerFaceColor','w',...
                'MarkerSize',markerSize);
        algorithm = AM;
        errorbar(numLabeledRangeMatrix,barSource(:,algorithm), stddev(:,algorithm),...
                '-g^','LineWidth',lineWidth,...
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
        set(gca,'XScale','log');
        set(gca, 'FontSize', 22);
        legend('MAD','AM','TACO', 'Location', 'SouthEast');
        xlabel('Number of Labeled Examples');
        %highLimitY = max(barSource(:)) * 1.05;
        %lowLimitY  = min(barSource(:)) * 0.9;
        set(gca,'YLim',[lowLimitY highLimitY]);
        set(gca,'XGrid','off','YGrid','on')
        ylabel(presentedKeyLabelY);
        directory = 'C:\technion\theses\Tex\SSL\GraphSSL_Confidence_Paper\figures\';
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
        nlpGraphNames = this.nlpGraphNames();
        numLabeledPerGraph = this.numLabeledPerGraphForTables();
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
        
            for graph_i = 1:length(nlpGraphNames)
                graph.value = nlpGraphNames(graph_i);
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
    %  find results with the given search properties.
    %  results are returned for CSSLMC, AM (without heuristics) and for
    %  MAD (with heuristics)
    %  results are not returned for CSSLMCF
    
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
        stringValues = cellstr(num2str(numeriaclValues, '%.1f'));
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
%        caption = ['results ' ...
%                   ' prior init mode ' diag('labelled init') ...
%                   ' balanced ' diag('balanced')
%                    ];
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
                     'avg macro MRR', 'avg levenshtein'};
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

