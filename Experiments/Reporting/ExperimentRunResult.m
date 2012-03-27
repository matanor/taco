classdef ExperimentRunResult < handle
    %EXPERIMENTRESULSSUMMARY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_resultCollection;
    end
    
methods
    %% create
    
    function create(this, experimentRun)
        numParameterRuns = experimentRun.numParameterRuns();
        for parameter_run_i=1:numParameterRuns
            Logger.log(['parameters run index = ' num2str(parameter_run_i) ]);
            parameterRun = experimentRun.getParameterRun(parameter_run_i);
            constructionParams = experimentRun.get_constructionParams();
            parameterRunResult = ParameterRunResult;
            parameterRunResult.create(parameterRun, constructionParams );
            this.addParameterRunResult(parameterRunResult);
        end
    end
    
    %% addParameterRunResult
    
    function addParameterRunResult(this, parameterRunResult)
        this.m_resultCollection = ...
            [this.m_resultCollection parameterRunResult];
    end
    
    %% printSummary
    
    function printSummary(this)
        this.printBigTableSummary();
        this.printSmallTablesSummary();
    end
    
    %% printBigTableSummary
    
    function printBigTableSummary(this)
        this.printBigTableTitle();
        for parameter_run_i=1:this.numParameterRuns()
            parameterRunResult = this.m_resultCollection(parameter_run_i);
            lines = parameterRunResult.toString_all();
            for line_i=1:length(lines)
                Logger.log( lines{line_i} );
            end
        end
    end
    
    %% printSmallTablesSummary
    
    function printSmallTablesSummary(this)
        numParameterRuns = this.numParameterRuns();
        wasReported = zeros(numParameterRuns);
        for parameter_run_i=1:numParameterRuns
            if ~wasReported(parameter_run_i)
                parameterRunResult = this.m_resultCollection(parameter_run_i);
                [similarParameterRun, similarParameterRunIndex ] = ...
                    this.findResultWithSimilarParams(parameterRunResult);
                if parameterRunResult.isUsingHeuristics()
                    withHeuristics = parameterRunResult;
                    noHeuristics = similarParameterRun;
                else
                    withHeuristics = similarParameterRun;
                    noHeuristics = parameterRunResult;
                end
                tablePrinter = ExcelTablePrinter(noHeuristics, withHeuristics);
                tablePrinter.printAllAvailableTables();
                wasReported(parameter_run_i) = 1;
                if ~isempty(similarParameterRun)
                    wasReported(similarParameterRunIndex) = 1;
                    Logger.log(['Similar parameter runs (with/without heuristics): '...
                         num2str(parameter_run_i) ' and ' num2str(similarParameterRunIndex)]);
                end
            end
        end
    end
    
    %% findResultWithSimilarParams
    
    function [R I] = findResultWithSimilarParams(this, parameterRunResult)
        parameterValues = parameterRunResult.parameterValues();
        parameterValues.useGraphHeuristics = ~parameterValues.useGraphHeuristics;
        [R I] = this.findResultWithParams(parameterValues);
    end
    
    %% findResultWithParams
    
    function [R I] = findResultWithParams(this, paramValuesToFind)
        R = [];
        I = [];
        for parameter_run_i=1:this.numParameterRuns
            parameterRunResult = this.m_resultCollection(parameter_run_i);
            paramValues = parameterRunResult.parameterValues();
            if this.isSameParameters(paramValuesToFind, paramValues)
                R = parameterRunResult;
                I = parameter_run_i;
                break;
            end
        end
    end
    
    %% numParameterRuns
    
    function R = numParameterRuns(this)
        R = length(this.m_resultCollection);
    end
end

methods (Static)
    %% isSameParameters
    
    function R = isSameParameters(A, B)
        R = 1;
        fields = fieldnames( A );
        for field_i=1:length(fields)
            fieldName = fields{field_i};
            if A.(fieldName) ~= B.(fieldName)
                R = 0;
                break;
            end
        end
    end
    
    %% printBigTableTitle
    
    function printBigTableTitle()
        SEPERATOR = ExcelTablePrinter.SEPERATOR;
        T = ['graph (M|A)' SEPERATOR];
        T = [T 'balanced (Y|N)' SEPERATOR];
        T = [T 'heuristics (Y|N)' SEPERATOR];
        T = [T 'labelled init (1|2)' SEPERATOR];
        T = [T 'optimize_by (P|B|N|M)' SEPERATOR];
        T = [T 'Algorithm' SEPERATOR];
        T = [T 'avg PRBEP (stddev)' SEPERATOR];
        T = [T 'avg accuracy (stddev)' SEPERATOR];
        T = [T 'avg macro accuracy (stddev)' SEPERATOR];
        T = [T 'avg MRR (stddev)' SEPERATOR];
        T = [T 'avg macro MRR (stddev)' SEPERATOR];
        T = [T 'optimized PRBEP' SEPERATOR];
        T = [T 'optimized accuracy' SEPERATOR];
        T = [T 'optimized macro accuracy' SEPERATOR];
        T = [T 'optimized MRR' SEPERATOR];
        T = [T 'optimized macro MRR' SEPERATOR];
        T = [T 'alpha' SEPERATOR];
        T = [T 'beta' SEPERATOR];
        T = [T 'gamma' SEPERATOR];
        T = [T 'K' SEPERATOR];
        T = [T 'mu1' SEPERATOR];
        T = [T 'mu2' SEPERATOR];
        T = [T 'mu3' SEPERATOR];
        T = [T 'am_v'       SEPERATOR];
        T = [T 'am_mu'      SEPERATOR];
        T = [T 'am_alpha'   SEPERATOR];

        Logger.log(T);
    end
   
end
    
end

