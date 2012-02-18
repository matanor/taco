classdef PRBEPTablePrinter < handle
    %PRBEPTABLEPRINTER Summary of this class goes here
    %   Detailed explanation goes here
    
properties
    m_noHeuristics;     % ParameterRunResult
    m_withHeuristics;   % ParameterRunResult
end

properties(Constant)
    SEPERATOR = ',';
    EMPTY_CELL = ',';
end
    
methods
    %% construtor
    
    function this = PRBEPTablePrinter( noHeuristics, withHeuristics)
        this.m_noHeuristics     = noHeuristics;
        this.m_withHeuristics   = withHeuristics;
    end
    
    %% printAllAvailableTables
    
    function printAllAvailableTables(this)
        for optimization_method_i=this.optimizationMethodsCollection()
            isEstimated = 0;
            this.print( optimization_method_i, isEstimated );
            this.printBlankRow();
            isEstimated = 1;
            this.print( optimization_method_i, isEstimated );
            this.printBlankRow();
        end
    end
    
    %% printBlankRow
    
    function printBlankRow(this)
        numAlgorithms = MultipleRunsResult.algorithmsResultOrder();
        blankRow(1:(numAlgorithms*2))=this.EMPTY_CELL;
        disp(blankRow);
    end
    
    %% print
    
    function print(this, optimizeMethod, isEstimated )
        parameterValues = this.nonEmptyParameterRun().parameterValues();
        this.printPRBEPtitle( parameterValues, optimizeMethod, isEstimated );
        this.printPRBEPtable( optimizeMethod, isEstimated );
        this.printAvgAccuracy( optimizeMethod );
    end
    
    %% printPRBEPtitle
    
    function printPRBEPtitle( this, parameterValues, optimizeMethod, isEstimated )
        if isEstimated
            isEstimatedString = 'est';
        else
            isEstimatedString = 'avg';
        end
        
        graphName = FileHelper.fileName(parameterValues.fileName);
        numEvaluationStr = num2str( parameterValues.numEvaluationRuns);
        optimizedStr = OptimizationMethodToStringConverter.convert(optimizeMethod);
        isBalanced =  parameterValues.balanced;
        if isBalanced 
            isBalancedStr = 'balanced';
        else
            isBalancedStr = 'unbalanced';
        end
        labeledInitModeStr = num2str(parameterValues.labeledInitMode);
        algorithmsStr = [];
        for algorithm_i=MultipleRunsResult.algorithmsResultOrder()
            algorithmName = AlgorithmTypeToStringConverter.convert(algorithm_i);
            algorithmsStr = [algorithmsStr algorithmName this.SEPERATOR]; %#ok<AGROW>
        end
        
        firstLine = [this.EMPTY_CELL ...
                     this.EMPTY_CELL ...
                     isEstimatedString ' PRBEP' this.SEPERATOR...
                     graphName this.SEPERATOR ...
                     numEvaluationStr ' runs' this.SEPERATOR ...
                     'optimized (' optimizedStr ')' this.SEPERATOR ...
                     isBalancedStr this.SEPERATOR ...
                     'labeled init mode ' labeledInitModeStr ];
        secondLine = [this.EMPTY_CELL ...
                      'No Heuristics' this.SEPERATOR...
                      this.EMPTY_CELL this.EMPTY_CELL ...
                      'With Heuristics' this.SEPERATOR ...
                      this.EMPTY_CELL this.EMPTY_CELL this.EMPTY_CELL ];
         thirdLine = [this.EMPTY_CELL ...
                      algorithmsStr ...
                      algorithmsStr ...
                      'paper'];
         disp(firstLine);
         disp(secondLine);
         disp(thirdLine);
    end
    
    %% printPRBEPtable
    
    function printPRBEPtable(this, optimizationMethod, isEstimated)
        T1 = this.getPRBEPresultsTable...
                (this.m_noHeuristics, optimizationMethod, isEstimated );
        T1_mean = mean(T1);
        T2 = this.getPRBEPresultsTable...
                (this.m_withHeuristics, optimizationMethod, isEstimated );
        T2_mean = mean(T2);
        numClasses = this.numClasses(optimizationMethod);        
        classesIndex = (1:numClasses).';
        prbepTable = [classesIndex T1       T2;
                      0            T1_mean  T2_mean] ;
        Utilities.printCommaSeperatedMatrix( prbepTable );
    end
    
    %% printAvgAccuracy
    
    function printAvgAccuracy(this, optimizationMethod)
        T1 = this.getAvgAccuracy(this.m_noHeuristics, optimizationMethod);
        T2 = this.getAvgAccuracy(this.m_withHeuristics, optimizationMethod);
        avgAccuracyTable = [0 T1 T2];
        Utilities.printCommaSeperatedMatrix(avgAccuracyTable);
    end
    
    %% getPRBEPresultsTable
    
    function R = getPRBEPresultsTable...
            (this, parameterRunResults, optimizationMethod, isEstimated)
        numClasses = this.numClasses(optimizationMethod);
        numAlgorithmsInResult = PRBEPTablePrinter.numAlgorithmInResult();
        if ~isempty(parameterRunResults)
            R = parameterRunResults.resultsTablePRBEP...
                    (optimizationMethod, isEstimated);
        else
            R = zeros(numClasses, numAlgorithmsInResult);
        end
    end
    
    %% getAvgAccuracy
    
    function R = getAvgAccuracy...
            (~, parameterRunResults, optimizationMethod)
        numAlgorithmsInResult = PRBEPTablePrinter.numAlgorithmInResult();
        if ~isempty(parameterRunResults)
            R = parameterRunResults.avgAccuracy_testSet(optimizationMethod);
        else
            R = zeros(1, numAlgorithmsInResult);
        end
    end
    
    %% numClasses
    
    function R = numClasses(this, optimization_method_i)
        parameterRun = this.nonEmptyParameterRun();
        R = parameterRun.numClasses(optimization_method_i);
    end
    
    %% nonEmptyParameterRun
    
    function R = nonEmptyParameterRun(this)
        if ~isempty(this.m_noHeuristics)
            R = this.m_noHeuristics;
        else
            R = this.m_withHeuristics;
        end
    end
    
    %% optimizationMethodsCollection
    
    function R = optimizationMethodsCollection(this)
        R = this.nonEmptyParameterRun().optimizationMethodsCollection();
    end
    
end

methods (Static)
    %% numAlgorithmInResult
    
    function R = numAlgorithmInResult()
        R = length(MultipleRunsResult.algorithmsResultOrder());
    end
end
    
end

