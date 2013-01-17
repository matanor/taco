classdef TextGraphs < TextReporterBase

    
methods (Access  = private)

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
    set(gca,'XGrid','off','YGrid','on');
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

end % private methods
    
end % classdef