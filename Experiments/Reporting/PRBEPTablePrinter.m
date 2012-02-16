classdef PRBEPTablePrinter < handle
    %PRBEPTABLEPRINTER Summary of this class goes here
    %   Detailed explanation goes here
    
properties
    m_noHeuristics;
    m_withHeuristics;
end
    
methods
    %% construtor
    
    function this = PRBEPTablePrinter( noHeuristics, withHeuristics)
        this.m_noHeuristics     = noHeuristics;
        this.m_withHeuristics   = withHeuristics;
    end
    
    %% print
    
    function print(this, optimizeMethod, isEstimated )
        parameterValues = this.nonEmptyParameterRun().parameterValues();
        this.printPRBEPtitle( parameterValues, optimizeMethod, isEstimated );
        this.printPRBEPtable( optimizeMethod, isEstimated );
    end
    
    %% printPRBEPtitle
    
    function printPRBEPtitle( ~, parameterValues, optimizeMethod, isEstimated )
        SEPERATOR = ',';
        EMPTY_CELL = SEPERATOR;

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
            algorithmsStr = [algorithmsStr algorithmName SEPERATOR]; %#ok<AGROW>
        end
        
        firstLine = [EMPTY_CELL ...
                     EMPTY_CELL ...
                     isEstimatedString ' PRBEP' SEPERATOR...
                     graphName SEPERATOR ...
                     numEvaluationStr ' runs' SEPERATOR ...
                     'optimized (' optimizedStr ')' SEPERATOR ...
                     isBalancedStr SEPERATOR ...
                     'labeled init mode ' labeledInitModeStr ];
        secondLine = [EMPTY_CELL ...
                      'No Heuristics' SEPERATOR...
                      EMPTY_CELL EMPTY_CELL ...
                      'With Heuristics' SEPERATOR ...
                      EMPTY_CELL EMPTY_CELL EMPTY_CELL ];
         thirdLine = [EMPTY_CELL ...
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
        T2 = this.getPRBEPresultsTable...
                (this.m_withHeuristics, optimizationMethod, isEstimated );
        numClasses = this.numClasses(optimizationMethod);        
        classesIndex = (1:numClasses).';
        prbepTable = [classesIndex T1 T2] ;
        Utilities.printCommaSeperatedMatrix( prbepTable );
    end
    
    %% getPRBEPresultsTable
    
    function R = getPRBEPresultsTable...
            (this, parameterRun, optimizationMethod, isEstimated)
        numClasses = this.numClasses(optimizationMethod);
        numAlgorithmsInResult = PRBEPTablePrinter.numAlgorithmInResult();
        if ~isempty(parameterRun)
            R = parameterRun.resultsTablePRBEP...
                    (optimizationMethod, isEstimated);
        else
            R = zeros(numClasses, numAlgorithmsInResult);
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
    
end

methods (Static)
    %% numAlgorithmInResult
    
    function R = numAlgorithmInResult()
        R = length(MultipleRunsResult.algorithmsResultOrder());
    end
end
    
end

