classdef SummaryReaderBase < TextReader

%% file name on office desktop
% For paper 2012_TACO_in_ECML
% fileName = 'C:/technion/theses/Experiments/results/2012_04_22_For_Paper_Graph_based_transduction_with_Confidence/BigTableSummary.txt';    
% For paper 2012 TACO on speech EILAT IEEEI
% fileName = 'C:/technion/theses/Experiments/results/2012_09_02_01 Speech Results Summary For Paper/BigTableSummary.txt'

%% file name on home desktop
% For paper 2012_TACO_in_ECML
% fileName = 'e:/technion/theses/Experiments/results/2012_04_22_For_Paper_Graph_based_transduction_with_Confidence/BigTableSummary.txt';    
% For paper 2012 TACO on speech EILAT IEEEI
% fileName = 'e:/technion/theses/Experiments/results/2012_09_02_01 Speech Results Summary For Paper/BigTableSummary.txt'

%% properties
    
properties
    m_allResults;
    m_resultMaps;
    m_header;
    m_numResults;
end

methods (Access = public)

%% Constructor
function this = SummaryReaderBase()
    this.m_allResults = [];
    this.m_numResults = 0;
    this.m_resultMaps = [];
end

%% convert

function convert(this, fileName)    
    this.load(fileName);
    this.doConvert();   % overide this
    %this.createGraphs_eilat_2012();
    %this.createGraphs_ecml_2012();
    %this.createTables_ecml2012();
    %this.createWebKBTable();
    %this.createMultipleDatasetGraphs();
    this.clearAll();
end

%% init
function init(this)
    init@TextReader(this);
    this.clearAll();
end 

%% doConvert

function doConvert(~)
    % hook for derived classes
end

%% processSingleLine

function processSingleLine(this, line, line_i) %#ok<INUSD,MANU>
    if this.isHeader(line, line_i)
        this.readHeader(line);
    else
        this.readResult(line);
    end
end
    
end % public methods
   
methods (Access = protected)

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
    if length(diag) ~= 1
        Logger.log(['SummaryReaderBase::findAlgorithms. length(diag) = ' num2str(length(diag)) '. Should be 1.']);
        assert(false);
    end
    diag = diag {1};

%         algorithm.value = {CSSLMCF.name()};
%         full = this.findEntries([searchProperties heuristics algorithm]);
%         assert( length(full) == 1);
%         full = full {1};

    algorithm.value = {AM.name()};
    am = this.findEntries([searchProperties heuristics algorithm]);
    assert( length(am) == 1);
    am = am{1};

    algorithm.value = {QC.name()};
    qc = this.findEntries([searchProperties heuristics algorithm]);
    assert( length(qc) == 1);
    qc = qc{1};

    heuristics.value = {'1'};

    algorithm.value = {MAD.name()};
    mad = this.findEntries([searchProperties heuristics algorithm]);
    assert( length(mad) == 1);
    mad = mad{1};

    R.diag = diag;
    R.am = am;
    R.mad = mad;
    R.qc = qc;
end

%% findEntries

function R = findEntries( this, searchProperties)
    R = [];
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
    if isempty(R)
%         Logger.log(['SummaryReaderBase::findEntries. searchKeys = ' ...
%                      '. searchValues = ' [searchValues{:}] ]);
        assert(false);
    end
end

end % protected methods 

methods (Access = private)

%% load
function load( this, fileName)
    this.set_inputFileName( fileName );
    this.init();
    this.read(this.READ_ALL);
    this.close();
    this.trimHeaders();
    this.createMaps();
    isTrimLevenshtein = 0;
    this.trimValues(isTrimLevenshtein);
end
    
%% clearAll

function clearAll(this)
    this.m_allResults = [];
    this.m_numResults = 0;
    this.m_resultMaps = [];
    this.m_header = [];
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

function trimValues(this, isTrimLevenshtein)
    trimKeys = { 'avg PRBEP', 'avg accuracy', ...
                 'avg macro accuracy', 'avg MRR', ...
                 'avg macro MRR'};
    if isTrimLevenshtein
       trimKeys{end+1} = 'avg levenshtein';
    end

    for result_i=1:length(this.m_resultMaps)
        map = this.m_resultMaps{result_i};
        for key_i = 1:length(trimKeys)
            key             = trimKeys{key_i};
            originalValue   = map(key);
            map(key)        = SummaryReaderBase.trim(originalValue);
            sttdev          = SummaryReaderBase.parseStddev(originalValue);
            stddevKey       = SummaryReaderBase.stddevKey(key);
            map(stddevKey)  = sttdev;
        end
        this.m_resultMaps{result_i} = map;
    end        
end

%% trimHeaders

function trimHeaders(this)
    for header_i = 1:length(this.m_header)
        this.m_header{header_i} = this.trim(this.m_header{header_i});
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

end %private methods

methods (Static)
    
function run()
    this = SummaryReaderBase();
    fileName = ['C:\technion\theses\Experiments\results\For Paper\' ...
                'BigTableSummary.txt'];
    this.convert(fileName);
end

%% removeExtraWhiteSpaceMargin
%  http://dopplershifted.blogspot.co.il/2008/07/programmatically-saving-matlab-figures.html
%  remove extra white space margins around figure
    
function removeExtraWhiteSpaceMargin(axisObject) % pass axisObject = gca
    set(axisObject,'LooseInset',get(axisObject,'TightInset'))
end

%% saveAndCloseFigure
    
function saveAndCloseFigure(fig, outputDirectory, fileNamePrefix, fileNameSuffix)
    fileName = [fileNamePrefix fileNameSuffix] ;
    fileFullPath = [ outputDirectory fileName '.pdf'];
    Logger.log(['SummaryReaderBase::saveAndCloseFigure. '...
                'Saving figure to ''' fileFullPath '''']);
    saveas(fig, fileFullPath ); 
    % saving directly to jpeg or tiff may look ugly (square points are missing)
    fileFullPath = [ outputDirectory fileName '.jpg'];
    Logger.log(['ExcelToLatexConverter::saveAndCloseFigure. '...
                'Saving figure to ''' fileFullPath '''']);
    saveas(fig, fileFullPath ); 
%     print(fig, '-djpeg', '-r600', fileFullPath); % -r<dots per inch>
    close(fig);        
end

%% stddevKey

function R = stddevKey(key)
    R = ['stddev ' key];
end

%% trim

function S = trim(S)
    trimPosition = find(S == '(');
    if ~isempty(trimPosition)
        S = S(1:(trimPosition-1));
    end
    S = strtrim(S);
end

%% parseStddev

function S = parseStddev(S)
    trimStart = find( S == '(' );
    trimEnd = find( S == ')' );
    if ~isempty(trimStart) && ~isempty(trimEnd)
        S = S(trimStart+1:trimEnd-1);
    else
        Logger.log(['parseStddev::Error. Cannot trim value ''' S '''']);
    end
    S = strtrim(S);
end

end % static methods
    
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
    
end

