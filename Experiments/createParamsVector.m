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

