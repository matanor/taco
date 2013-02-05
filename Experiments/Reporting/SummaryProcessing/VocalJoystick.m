classdef VocalJoystick < SummaryReaderBase

%% office
% fileName = 'C:/technion/theses/Tex/SSL/Thesis/Results/thesis_results.txt';
%% home
% fileName = 'E:/technion/theses/Tex/SSL/Thesis/Results/thesis_results.txt';

properties (Constant)
    V4_W1 = VJGenerator.V4_W1;
    V4_W7 = VJGenerator.V4_W7;
    V8_W1 = VJGenerator.V8_W1;
    V8_W7 = VJGenerator.V8_W7;
end% constant properties

methods (Static)
    
%% outputDirectory

function R = outputDirectory()
    R = 'E:/technion/theses/Tex/SSL/Thesis/figures/vocal_joystick/';
end

%% run

function run(fileName)
    this = VocalJoystick();
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
    Logger.log('VocalJoystick::create.');
    this.createTables();
end

%% createTables

function createTables(this)
    for isTacoVariants = [0 1]
        Logger.log(['VocalJoystick::createTables. isTacoVariants = ' num2str(isTacoVariants)] );
        Logger.log('VocalJoystick::createTables. Data sets table.' );
        results = this.gatherData_allDataSets(isTacoVariants );
        this.outputTable_allDataSets(results, isTacoVariants );
        Logger.log('VocalJoystick::createTables. percent labeled table.' );
        results = this.gatherData_allPrecentLabeled(isTacoVariants);
        this.outputTable_allPercentLabeled(results, isTacoVariants);
    end
end

%% gatherData_allDataSets

function R = gatherData_allDataSets(this, isTacoVariants)
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
    taco_objective.shouldMatch = 1;
    if ~isTacoVariants
       taco_objective.value = {num2str(CSSLBase.OBJECTIVE_HARMONIC_MEAN)};
    end
    
    percent_labeled.key = 'precent labeled';
    percent_labeled.value = {'1'};
    percent_labeled.shouldMatch = 1;
    
    optimize_by.key         = 'optimize_by';
    optimize_by.shouldMatch = 1;
    optimize_by.value      = {'accuracy'};
    
    taco_algorithm.key = 'Algorithm';
    taco_algorithm.shouldMatch = 1;
    taco_algorithm.value = {CSSLMC.name()};

    searchProperties = [balanced labeled_init num_iterations ...
                        optimize_by percent_labeled];

    graph.key = 'graph';
    graph.shouldMatch = 1;
    
    graphsOrderInTable = VocalJoystick.graphsOrderInTable();
    allGraphNames      = VocalJoystick.allGraphNames();
    TACO_variants_order= VocalJoystick.TACO_variants_order();
    
    for graph_ID = graphsOrderInTable
        graph.value = allGraphNames(graph_ID);
        Logger.log(['VocalJoystick::gatherData_allDataSets. Looking results for graph ''' graph.value{1} '''']);
        if ~isTacoVariants
            graph_result = this.findAlgorithms([searchProperties graph taco_objective]); 
            R{graph_ID}  = graph_result;  %#ok<AGROW>
        else
            for TACO_variant_ID = TACO_variants_order
                taco_objective.value = {num2str(TACO_variant_ID)};
                R{graph_ID,TACO_variant_ID} = ...
                    this.findEntries([searchProperties graph taco_algorithm taco_objective ]); %#ok<AGROW>    
            end
        end
    end
end

%% gatherData_allPrecentLabeled

function R = gatherData_allPrecentLabeled(this, isTacoVariants)
    balanced.key            = 'balanced';
    balanced.value          = {'0'};
    balanced.shouldMatch    = 1;

    labeled_init.key        = 'labelled init';
    labeled_init.value      = {'1'};
    labeled_init.shouldMatch= 1;

    num_iterations.key          = 'max iterations';
    num_iterations.value        = {'20'};
    num_iterations.shouldMatch  = 1;
    
    taco_objective.key          = 'TACO objective';
    
    taco_objective.shouldMatch  = 1;
    if ~isTacoVariants
       taco_objective.value        = {num2str(CSSLBase.OBJECTIVE_HARMONIC_MEAN)};
    end
    
    optimize_by.key         = 'optimize_by';
    optimize_by.shouldMatch = 1;
    optimize_by.value       = {'accuracy'};

    allGraphNames       = VocalJoystick.allGraphNames();
    graph.key           = 'graph';
    graph.shouldMatch   = 1;
    graph.value         = allGraphNames(VocalJoystick.V8_W7);
    
    searchProperties = [balanced labeled_init num_iterations ...
                        optimize_by graph];
                    
    taco_algorithm.key = 'Algorithm';
    taco_algorithm.shouldMatch = 1;
    taco_algorithm.value = {CSSLMC.name()};

    percent_labeled.key = 'precent labeled';
    percent_labeled.shouldMatch = 1;
          
    percentLabeledRange = VocalJoystick.allPercentLabeledRange();
    TACO_variants_order = VocalJoystick.TACO_variants_order();
    result_i = 1;
    for percentLabeled_i = percentLabeledRange
        percent_labeled.value = {num2str(percentLabeled_i)};
        if ~isTacoVariants
            result = this.findAlgorithms([searchProperties percent_labeled taco_objective]); 
            R{result_i}  = result;  %#ok<AGROW>
        else
            for TACO_variant_ID = TACO_variants_order
                taco_objective.value = {num2str(TACO_variant_ID)};
                R{result_i,TACO_variant_ID} = ...
                    this.findEntries([searchProperties percent_labeled taco_algorithm taco_objective]); %#ok<AGROW>    
            end
        end
        result_i = result_i + 1;
    end
end

%% outputTable_allDataSets

function outputTable_allDataSets(~,results, isTacoVariants )
    allGraphNamesForTables  = VocalJoystick.allGraphNamesForTables();
    graphsOrderInTable      = VocalJoystick.graphsOrderInTable();
    presentedKey            = 'avg accuracy';
    
    allResults = [];
    for graph_ID = graphsOrderInTable
        if ~isTacoVariants
            graphResult = results{graph_ID};
        else
            graphResult = results(graph_ID,:);
        end
        graphNameForTable = allGraphNamesForTables{graph_ID};
        numericLineResults = VocalJoystick.printSingleLine(graphResult, presentedKey, graphNameForTable, isTacoVariants );
        allResults = [allResults; numericLineResults]; %#ok<AGROW>
    end
    totalAverage = mean(allResults, 1);
    TextTables.averageTable_printLine(totalAverage, 'Average');
end

%% outputTable_allPercentLabeled

function outputTable_allPercentLabeled(~, results, isTacoVariants)
	allPercentLabeledRange = VocalJoystick.allPercentLabeledRange();
    presentedKey            = 'avg accuracy';
    
    if size(results,1) ~= 1
        numResults = size(results,1);
    else
        numResults = size(results,2);
    end
    allResults = [];
    for result_i = 1:numResults
        if ~isTacoVariants
            oneResult = results{result_i};
        else
            oneResult = results(result_i,:);
        end
        rowKey    = num2str(allPercentLabeledRange(result_i));
        rowKey    = [rowKey '\%']; %#ok<AGROW>
        numericLineResults = VocalJoystick.printSingleLine(oneResult, presentedKey, rowKey, isTacoVariants);
        allResults = [allResults; numericLineResults]; %#ok<AGROW>
    end
    totalAverage = mean(allResults, 1);
    TextTables.averageTable_printLine(totalAverage, 'Average');
end

end % private methods

methods (Static)

%% TACO_variants_order

function R = TACO_variants_order()
    R = [CSSLBase.OBJECTIVE_HARMONIC_MEAN_SINGLE ...
         CSSLBase.OBJECTIVE_HARMONIC_MEAN        ...CSSLBase.OBJECTIVE_MULTIPLICATIVE             ...
         CSSLBase.OBJECTIVE_WEIGHTS_UNCERTAINTY_SINGLE ...
         CSSLBase.OBJECTIVE_WEIGHTS_UNCERTAINTY  ...
          ];
end
    
%% printSingleLine

function R = printSingleLine(graphResult, presentedKey, rowKey, isTacoVariants)
    TACO_variants_order = VocalJoystick.TACO_variants_order();
    if ~isTacoVariants
        resultsAsStrings  = TextTables.baselines_toStrings(presentedKey, graphResult);
    else
        resultsAsStrings = TextTables.tacoVariantsResults_toStrings...
                   (graphResult, TACO_variants_order, presentedKey);
    end
    R = cellfun(@str2num, resultsAsStrings);
    if size(R,1) ~= 1
        R = R.'; % make row vector
    end
    resultsAsStrings  = TextTables.markBoldStrings(resultsAsStrings, 100);
    lineFormat = '~%s~ & ~%s~ & ~%s~ & ~%s~ & ~%s~ \\\\ \\hline\n';
    fprintf( lineFormat, ...., 
        rowKey, ...
        resultsAsStrings{1}, ...
        resultsAsStrings{2}, ...
        resultsAsStrings{3}, ...
        resultsAsStrings{4} );   
end
    
%% allPercentLabeledRange

function R = allPercentLabeledRange()
    R = [0.01 0.1 1 10 20];
end

%% graphsOrderInTable
    
function R = graphsOrderInTable()    
    R = [VocalJoystick.V8_W7 VocalJoystick.V8_W1 VocalJoystick.V4_W7 VocalJoystick.V4_W1];
end
    
%% allGraphNames

function R = allGraphNames()
    R{VocalJoystick.V4_W1} = VocalJoystick.graphName( 4, 1 );
    R{VocalJoystick.V4_W7} = VocalJoystick.graphName( 4, 7 );
    R{VocalJoystick.V8_W1} = VocalJoystick.graphName( 8, 1 );
    R{VocalJoystick.V8_W7} = VocalJoystick.graphName( 8, 7 );
end

%% allGraphNamesForTables

function R = allGraphNamesForTables()
    R{VocalJoystick.V4_W1} = '\vjFour';
    R{VocalJoystick.V4_W7} = '\vjThree';
    R{VocalJoystick.V8_W1} = '\vjTwo';
    R{VocalJoystick.V8_W7} = '\vjOne';
end

%% graphName

function  R = graphName( numVowels, contextSize)
    R = ['trainAndTest.instances.v' num2str(numVowels) '.w' num2str(contextSize) '.k_10.lihi'];
end
    
end % static methods

end % classdef