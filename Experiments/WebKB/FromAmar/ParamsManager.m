classdef ParamsManager < handle
    %PARAMSMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
methods (Static)
    
    function paramStructs = createConstructionParamsStructures( paramProperties )
        %CREATEPARAMSTRUCTS Summary of this function goes here
        %   Detailed explanation goes here
        
        paramsVector = ParamsManager.createParamsVector( paramProperties );

        numStructs = size(paramsVector ,1);
        paramStructs = [];

        for struct_i=1:numStructs
            new = ConstructionParams;
            paramIndex = ParamsManager.findParamIndex( paramProperties, 'K');
            new.K = paramsVector (struct_i, paramIndex);
            
            paramIndex = ParamsManager.findParamIndex( paramProperties, 'numLabeled');
            new.numLabeled  = paramsVector (struct_i, paramIndex);
            
            paramIndex = ParamsManager.findParamIndex( paramProperties, 'numInstancesPerClass');
            new.numInstancesPerClass  = paramsVector (struct_i, paramIndex);
            
            paramIndex = ParamsManager.findParamIndex( paramProperties, 'numFolds');
            new.numFolds  = paramsVector (struct_i, paramIndex);

            paramStructs = [paramStructs; new];
        end
    end

    function paramStructs = createAlgorithmParamsStructures( paramProperties )
        %CREATEPARAMSTRUCTS Summary of this function goes here
        %   Detailed explanation goes here
        
        paramsVector = ParamsManager.createParamsVector( paramProperties );

        numStructs = size(paramsVector,1);
        paramStructs = [];

        for struct_i=1:numStructs
            
            paramIndex = ParamsManager.findParamIndex( paramProperties, 'alpha');
            new.alpha = paramsVector(struct_i, paramIndex);
            
            paramIndex = ParamsManager.findParamIndex( paramProperties, 'beta');
            new.beta = paramsVector(struct_i, paramIndex);
            
            paramIndex = ParamsManager.findParamIndex( paramProperties, 'labeledConfidence');
            new.labeledConfidence = paramsVector(struct_i, paramIndex);
            
            paramIndex = ParamsManager.findParamIndex( paramProperties, 'makeSymetric');
            new.makeSymetric = paramsVector(struct_i, paramIndex);

            paramIndex = ParamsManager.findParamIndex( paramProperties, 'numIterations');
            new.numIterations = paramsVector(struct_i, paramIndex);
            
            paramIndex = ParamsManager.findParamIndex( paramProperties, 'useGraphHeuristics');
            new.useGraphHeuristics = paramsVector(struct_i, paramIndex);

            paramStructs = [paramStructs; new];
        end
    end
    
    function result = findParamIndex...
            ( paramProperties, paramName)
        numParams = length(paramProperties);
        for param_i=1:numParams;
            singleParamProperties = paramProperties(param_i);
            if (strcmp(paramName,singleParamProperties.name))
                result = param_i;
                return;
            end
        end
    end

    function params = createParamsVector( paramProperties )
        %CREATEPARAMSVECTOR Summary of this function goes here
        %   Detailed explanation goes here

        numParams = length(paramProperties);

        params = [];

        for param_i=1:numParams
           singleParamProperties = paramProperties(param_i);
           currentParamRange = singleParamProperties.range;
           % make column vector
           currentParamRange = currentParamRange.';
           params = cartesianProduct( params, currentParamRange );
        end

    end

end % methods (Static)
    
end % classdef

