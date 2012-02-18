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
            disp(['parameters run index = ' num2str(parameter_run_i) ]);
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
end
    
end

