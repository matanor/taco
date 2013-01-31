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
%     results = this.gatherData_allDataSets();
%     this.outputTable_allDataSets(results);
    results = this.gatherData_allPrecentLabeled();
    this.outputTable_allPercentLabeled(results);
end

%% gatherData_allDataSets

function R = gatherData_allDataSets(this)
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
    
    percent_labeled.key = 'precent labeled';
    percent_labeled.value = {'1'};
    percent_labeled.shouldMatch = 1;
    
    optimize_by.key         = 'optimize_by';
    optimize_by.shouldMatch = 1;
    optimize_by.value      = {'accuracy'};

    searchProperties = [balanced labeled_init num_iterations taco_objective ...
                        optimize_by percent_labeled];

    graph.key = 'graph';
    graph.shouldMatch = 1;
    
    graphsOrderInTable = VocalJoystick.graphsOrderInTable();
    allGraphNames      = VocalJoystick.allGraphNames();
    for graph_ID = graphsOrderInTable
        graph.value = allGraphNames(graph_ID);
        graph_result = this.findAlgorithms([searchProperties graph]); 
        R{graph_ID}  = graph_result;  %#ok<AGROW>
%         R{graph_ID, AlgorithmProperties.AM}   = graph_result.am;  %#ok<AGROW>
%         R{graph_ID, AlgorithmProperties.CSSL} = graph_result.diag;%#ok<AGROW>
%         R{graph_ID, AlgorithmProperties.MAD}  = graph_result.mad; %#ok<AGROW>
%         R{graph_ID, AlgorithmProperties.QC}   = graph_result.qc;  %#ok<AGROW>
    end
end

%% gatherData_allPrecentLabeled

function R = gatherData_allPrecentLabeled(this)
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
    taco_objective.value        = {num2str(CSSLBase.OBJECTIVE_HARMONIC_MEAN)};
    taco_objective.shouldMatch  = 1;
    
    optimize_by.key         = 'optimize_by';
    optimize_by.shouldMatch = 1;
    optimize_by.value       = {'accuracy'};

    allGraphNames       = VocalJoystick.allGraphNames();
    graph.key           = 'graph';
    graph.shouldMatch   = 1;
    graph.value         = allGraphNames(VocalJoystick.V8_W7);
    
    searchProperties = [balanced labeled_init num_iterations taco_objective ...
                        optimize_by graph];

    percent_labeled.key = 'precent labeled';
    percent_labeled.shouldMatch = 1;
          
    percentLabeledRange = VocalJoystick.allPercentLabeledRange();
    result_i = 1;
    for percentLabeled_i = percentLabeledRange
        percent_labeled.value = {num2str(percentLabeled_i)};
        result = this.findAlgorithms([searchProperties percent_labeled]); 
        R{result_i}  = result;  %#ok<AGROW>
        result_i = result_i + 1;
    end
end

%% outputTable_allDataSets

function outputTable_allDataSets(this,results)
    allGraphNamesForTables  = VocalJoystick.allGraphNamesForTables();
    graphsOrderInTable      = VocalJoystick.graphsOrderInTable();
    presentedKey            = 'avg accuracy';
    
    for graph_ID = graphsOrderInTable
        graphResult = results{graph_ID};
        graphNameForTable = allGraphNamesForTables{graph_ID};
        VocalJoystick.printSingleLine(graphResult, presentedKey, graphNameForTable);
    end
end

%% outputTable_allPercentLabeled

function outputTable_allPercentLabeled(~, results)
	allPercentLabeledRange = VocalJoystick.allPercentLabeledRange();
    presentedKey            = 'avg accuracy';
    
    numResults = length(results);
    for result_i = 1:numResults
        oneResult = results{result_i};
        rowKey    = num2str(allPercentLabeledRange(result_i));
        rowKey    = [rowKey '\%'];
        VocalJoystick.printSingleLine(oneResult, presentedKey, rowKey);
    end
end

end % private methods

methods (Static)

%% printSingleLine

function printSingleLine(graphResult, presentedKey, rowKey)
    resultsAsStrings  = TextTables.metricToString(presentedKey, graphResult);
    lineFormat = '%s & %s & %s & %s & %s \\\\ \\hline\n';
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