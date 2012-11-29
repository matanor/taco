classdef ExperimentRun < handle
    %EXPERIMENTRUN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        m_constructionParams;
    end %(Access = public)
    
    properties (SetAccess = public, GetAccess=public)
        m_developmentGraph;
        m_testGraph;
        m_parameterRuns;
        m_trunsductionSets;
    end
    
methods (Access = public)
    
    %% constructor
    
    function this = ExperimentRun(constructionParams)
        this.m_constructionParams = constructionParams;
    end

    %% get_constructionParams
    
    function R = get_constructionParams(this)
        R = this.m_constructionParams;
    end
    
    %% constructGraph
    
    function constructGraph(this)
        this.m_developmentGraph = ExperimentGraph;
        developmentGraphFilePath = this.m_constructionParams.fileProperties.development;
        this.m_developmentGraph.load                    ( developmentGraphFilePath );
        this.m_developmentGraph.removeExtraSplitVertices( this.m_constructionParams.numFolds);        
        testGraphFilePath = this.m_constructionParams.fileProperties.test;
        if ~isempty(testGraphFilePath)
            Logger.log('ExperimentRun::constructGraph. Using seperate dev/test graphs');
            this.m_testGraph        = ExperimentGraph;
            this.m_testGraph.load( testGraphFilePath );
            this.m_testGraph.removeExtraSplitVertices( this.m_constructionParams.numFolds);
        end
    end
    
    %% createTrunstuctionSets
    
%     function createTrunstuctionSets(this)
%         trunsductionSetsFactory = ...
%             ExperimentTrunsductionSetsFactory( this.m_constructionParams, this.m_graph );
%         this.m_trunsductionSets = trunsductionSetsFactory.create();
%     end
    
    %% saveTrunsductionSets
    
%     function saveTrunsductionSets(this, outputFileFullPath )
%         Logger.log(['Saving trunsduction sets to ' outputFileFullPath '''']);
%         trunsductionSets = this.m_trunsductionSets; %#ok<NASGU>
%         save(outputFileFullPath, 'trunsductionSets');
%     end
    
    %% numLabeledToPrecent
    %  for speech, transduction sets are common to more than one graph.
    %  so the naming scheme for the transduction sets file name is
    %  different, this function translates from a number of labeled frames
    %  in the test graph, to the precent of labeled data used, which is
    %  part of the transduction file name scheme
    
    function R = numLabeledToPrecent(~, numLabeled)
        numLabeledToPrecentMap = containers.Map(uint32(1), 'dummy'); % KeyType is uint32.
        remove(numLabeledToPrecentMap,1);
        numLabeledToPrecentMap(11147)  = '001';
        numLabeledToPrecentMap(55456)  = '005';
        numLabeledToPrecentMap(111133) = '010';
        numLabeledToPrecentMap(221254) = '020';
        numLabeledToPrecentMap(331793) = '030';
        numLabeledToPrecentMap(553041) = '050';
        R = numLabeledToPrecentMap(numLabeled);
    end
        
    %% trunsductionSetsFileName
    
    function R = trunsductionSetsFileName(this)
        transductionSetFileFormat = this.m_constructionParams.fileProperties.transductionSetFileFormat;
        useNumLabeledToPrecent = 1; % default is 1
        if isfield(this.m_constructionParams.fileProperties,'useNumLabeledToPrecent');
            useNumLabeledToPrecent    = this.m_constructionParams.fileProperties.useNumLabeledToPrecent;
        end
        numLabeled = this.precentLabeledToNumLabeled(this.m_constructionParams);
        if ~isempty(transductionSetFileFormat)
            if useNumLabeledToPrecent
                fileNamePart = this.numLabeledToPrecent(numLabeled);
            else
                fileNamePart = num2str(this.m_constructionParams.precentLabeled);
            end
            R = sprintf(transductionSetFileFormat, fileNamePart);
        else
            R = this.constructTransductionSetFilePath...
                (this.m_constructionParams.fileProperties.development,...
                 numLabeled,...
                 this.m_constructionParams.balanced);
        end
    end
    
    %% constructTransductionSetFilePath
    
    function R = constructTransductionSetFilePath(~, graphFileFullPath, numLabeled, isBalanced)
        [path, name, ~] = fileparts(graphFileFullPath);
        numLabeledStr = num2str(numLabeled);
        if isBalanced 
            isBalancedStr = 'balanced';
        else
            isBalancedStr = 'unbalanced';
        end
        trunsductionFileName = [path '/' name '_TrunsSet_' isBalancedStr '_' numLabeledStr '.mat'];
        R = trunsductionFileName;
    end
    
    %% loadTrunsductionSets
    
    function loadTrunsductionSets(this)
        fileFullPath = this.trunsductionSetsFileName();
        Logger.log(['Loading trunsduction sets from ''' fileFullPath '''']);
        
        numLabeledRequired = this.precentLabeledToNumLabeled(this.m_constructionParams);
        fileData = load(fileFullPath);
        experimentTrunsductionSet = fileData.trunsductionSets;
        if (experimentTrunsductionSet.hasOptimizationSets())
            numLabeledFromFile = experimentTrunsductionSet.optimizationSet(1).numLabeled();
            Logger.log(['ExperimentRun::loadTrunsductionSets. num labeled in optimization' ...
                        ' trunsduction set (from file) = ' num2str(numLabeledFromFile)]);
            if numLabeledFromFile ~= numLabeledRequired
                Logger.log(['ExperimentRun::loadTrunsductionSets. WARNING ' ...
                            ' num labeled required (' num2str(numLabeledRequired) ...
                            ') is different from num labeled in file (' num2str(numLabeledFromFile)...
                            ')' ]);
            end
        end
        if (experimentTrunsductionSet.hasEvaluationSets())
            for evaluation_set_i=1:experimentTrunsductionSet.numEvaluationSets()
                numLabeledFromFile = experimentTrunsductionSet.evaluationSet(1).numLabeled();
                Logger.log(['ExperimentRun::loadTrunsductionSets. num labeled in evaluation' ...
                            ' trunsduction set ' num2str(evaluation_set_i) ...
                            ' (from file) = ' num2str(numLabeledFromFile)]);
                if numLabeledFromFile ~= numLabeledRequired
                    Logger.log(['ExperimentRun::loadTrunsductionSets. WARNING ' ...
                                ' num labeled required (' num2str(numLabeledRequired) ...
                                ') is different from num labeled in file (' num2str(numLabeledFromFile)...
                                ')' ]);
                end
            end
        end
        
        this.m_trunsductionSets = experimentTrunsductionSet;
    end
    
    %% createParameterRun
    
    function R = createParameterRun(this, parameterValues)
        R = ParameterRun(this.m_constructionParams, this.m_developmentGraph, ...
                         this.m_testGraph, this.m_trunsductionSets,   parameterValues);
    end
    
    %% addParameterRun
    
    function addParameterRun(this, value)
        this.m_parameterRuns = [this.m_parameterRuns;value];
    end
    
    %% getParameterRun
    
    function R = getParameterRun(this, index)
        R = this.m_parameterRuns(index);
    end
    
    %% numParameterRuns
    
    function R = numParameterRuns(this)
        R = length(this.m_parameterRuns);
    end
    
    %% clearGraphWeights
    
    function clearGraphWeights(this)
        if ~isempty(this.m_developmentGraph)
            this.m_developmentGraph.clearWeights();
        end
        if ~isempty(this.m_testGraph)
            this.m_testGraph.clearWeights();
        end
    end

end

methods (Static)
    
    %% precentLabeledToNumLabeled
    
    function r = precentLabeledToNumLabeled(constructionParams)
        precentLabeled           = constructionParams.precentLabeled;
        precentToNumLabeledTable = constructionParams.fileProperties.precentToNumLabeledTable;
        r = precentToNumLabeledTable(precentLabeled);
    end
    
end

    
end

