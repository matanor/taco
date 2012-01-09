function paramStructs = createParamStructs...
    ( paramProperties, params )
%CREATEPARAMSTRUCTS Summary of this function goes here
%   Detailed explanation goes here

numStructs = size(params,1);
paramStructs = [];

for struct_i=1:numStructs
    paramIndex = findParamIndex( paramProperties, 'K');
    new.constructionParams.K = params(struct_i, paramIndex);
    paramIndex = findParamIndex( paramProperties, 'alpha');
    new.algorithmParams.alpha = params(struct_i, paramIndex);
    paramIndex = findParamIndex( paramProperties, 'beta');
    new.algorithmParams.beta = params(struct_i, paramIndex);
    paramIndex = findParamIndex( paramProperties, 'labeledConfidence');
    new.algorithmParams.labeledConfidence = params(struct_i, paramIndex);
    paramIndex = findParamIndex( paramProperties, 'makeSymetric');
    new.algorithmParams.makeSymetric = params(struct_i, paramIndex);
    paramStructs = [paramStructs; new];
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

end

