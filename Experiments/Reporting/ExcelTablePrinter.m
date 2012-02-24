classdef ExcelTablePrinter < handle
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
    
    function this = ExcelTablePrinter( noHeuristics, withHeuristics)
        this.m_noHeuristics     = noHeuristics;
        this.m_withHeuristics   = withHeuristics;
    end
    
    %% printAllAvailableTables
    
    function printAllAvailableTables(this)
        for optimization_method_i=this.optimizationMethodsCollection()
            disp('**********************************');
            isEstimated = 0;
            this.print( optimization_method_i, isEstimated );
            this.printBlankRow();
            isEstimated = 1;
            this.print( optimization_method_i, isEstimated );
            this.printBlankRow();
            this.printOptimalParams( optimization_method_i );
        end
    end
    
    %% printOptimalParams
    
    function printOptimalParams(this, optimization_method_i)
        this.printOptimalParamTable...
            ( this.m_noHeuristics, optimization_method_i, 'No Heuristics' );
        this.printBlankRow();
        this.printOptimalParamTable...
            ( this.m_withHeuristics, optimization_method_i, 'With Heuristics');
    end
    
    %% printOptimalParamTable
    
    function printOptimalParamTable...
            (this, parameterRunResult, optimization_method_i, heuristicsTitle)
        this.printOptimalParamTableTitle(heuristicsTitle );
        for algorithm_i=MultipleRunsResult.algorithmsResultOrder()
            algorithmName = AlgorithmTypeToStringConverter.convert(algorithm_i);
            if ~isempty(parameterRunResult)
                optimal = parameterRunResult.get_optimalParams...
                            (optimization_method_i, algorithm_i);
                S = OptimalParamsToStringConverter.convert...
                    (optimal, algorithm_i, this.EMPTY_CELL, this.SEPERATOR );
                S = [S num2str(optimal.avgPRBEP) this.SEPERATOR ]; %#ok<AGROW>
                S = [S num2str(optimal.avgAccuracy) ]; %#ok<AGROW>
            else
                S = [];
            end
            S = [algorithmName this.SEPERATOR S]; %#ok<AGROW>
            disp(S);
        end
    end
        
    %% printOptimalParamTableTitle
    
    function printOptimalParamTableTitle(this, heuristicsTitle )
        firstRow = [this.EMPTY_CELL this.EMPTY_CELL ... 
                    'optimal' this.SEPERATOR ...
                    heuristicsTitle this.SEPERATOR ...
                    ];
        disp(firstRow);
        secondRow = [this.EMPTY_CELL ...
                     'alpha' this.SEPERATOR ...
                     'beta' this.SEPERATOR ...
                     'gamma' this.SEPERATOR ...
                     'K' this.SEPERATOR ...
                     'mu1' this.SEPERATOR ...
                     'mu2' this.SEPERATOR ...
                     'mu3' this.SEPERATOR ...
                     'optimal prbep' this.SEPERATOR ...
                     'optimal accuracy'];
         disp(secondRow);
    end
    
    %% printBlankRow
    
    function printBlankRow(this)
        numAlgorithms = this.numAlgorithmInResult();
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
        numAlgorithmsInResult = ExcelTablePrinter.numAlgorithmInResult();
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
        numAlgorithmsInResult = ExcelTablePrinter.numAlgorithmInResult();
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

