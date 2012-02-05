classdef ParamsManager < handle
    %PARAMSMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
properties (GetAccess = public, SetAccess = private)
    m_K;
    m_alpha;
    m_beta;
    m_labeledConfidence;
    m_mu2;
    m_mu3;
    m_makeSymetric;
    m_numIterations;
    m_numLabeled;
    m_numFolds;
    m_numInstancesPerClass; % is required ?
    m_useGraphHeuristics;
    m_fileName;
end
    
methods (Access = public)
    function this = ParamsManager() %constructor        
        
        isString = 1;
        fileNames = [ {'C:\technion\theses\Experiments\WebKB\data\Rapid_Miner_Result\webkb_constructed.mat'}];
        this = this.createParameter( 'fileName', [1] , isString, fileNames );
        
        isString = 0;
        this = this.createParameter(  'K', [1000], isString, [] );
        %K.range = [1,2,5,10,20,50,100,500];
        
        %alpha.range = [0.0001, 0.001, 0.01,0.1,1];
        %alpha.range = [10^(-5), 10^(-4), 0.001, 0.01,  1, 10^2, 10^4 ];
        this = this.createParameter( 'alpha', [1000], isString, [] );
        
        %beta.range = [1,10, 100,1000,10000];
        %beta.range = [10, 100, 10^3, 10^4,10^5, 10^6, 10^7, 10^8];
        %beta.range = [10^(-5), 10^(-4), 0.001, 0.01, 1, 10^2, 10^4 ];
        this = this.createParameter( 'beta', [1], isString, [] );
        
        this = this.createParameter( 'mu2', [1], isString, [] );     
        this = this.createParameter( 'mu3', [1], isString, [] );
        
        %labeledConfidence.range = [0.01,0.1];
        this = this.createParameter( 'labeledConfidence', [1], isString, [] );     
        
        this = this.createParameter( 'makeSymetric', [1], isString, [] );     
        
        %numIterations.range = [5 10 25 50 100];
        this = this.createParameter( 'numIterations', [1], isString, [] );    
        
        this = this.createParameter( 'numLabeled', [48], isString, [] );    
        
        this = this.createParameter( 'numFolds', [4], isString, [] );    
        
        % 0 means all instances
        this = this.createParameter( 'numInstancesPerClass', [0], isString, [] );    
        
        this = this.createParameter( 'useGraphHeuristics', [0 1], isString, [] );
        
    end
    
    %% createParameter
    
    function this = createParameter( this, name, range , isString, strValues)
        memebrName = ['m_' name];
        this.(memebrName).range = range;
        this.(memebrName).name = name;
        this.(memebrName).isString = isString;
        this.(memebrName).values = strValues;
    end
    
    %% algorithmParamsProperties
    
    function R = algorithmParamsProperties(this)
        R = [ this.m_alpha,        this.m_beta,          this.m_labeledConfidence, ...
              this.m_makeSymetric, this.m_numIterations, this.m_useGraphHeuristics];
    end
    
    %% constructionParamsProperties
    
    function R = constructionParamsProperties(this)
        R = [  this.m_fileName, this.m_K, this.m_numLabeled, this.m_numInstancesPerClass, this.m_numFolds];
    end
    
    %% optimizationParamsCSSL
    
    function R = optimizationParamsCSSL(this)
        R = [ this.m_alpha, this.m_beta, this.m_labeledConfidence];
    end
    
    %% optimizationParamsMAD
    function R = optimizationParamsMAD(this)
        R = [ this.m_mu2, this.m_mu3 ];
    end    
    
    %% evaluationParamsProperties
    function R = evaluationParamsProperties(this)
        R = [ this.m_useGraphHeuristics ];
    end        
    
    %% optimizationParams_allOptions

    function R = optimizationParams_allOptions(this, algorithmType)
        if (SingleRun.CSSLMC == algorithmType || SingleRun.CSSLMCF == algorithmType)
            optimizationParamProperties = this.optimizationParamsCSSL();
        elseif (SingleRun.MAD == algorithmType)
            optimizationParamProperties = this.optimizationParamsMAD();
        else
           disp([ 'Error: not parameter to optimize for algorithm' num2str(algorithmType) ]);
        end
        R = this.createParameterStructures( optimizationParamProperties );
    end
    
    %% constructionParams_allOptions
    
    function R = constructionParams_allOptions( this )
        paramProperties = this.constructionParamsProperties();
        R = this.createParameterStructures( paramProperties);
    end

    %% algorithmParams_allOptions
    
    function R = algorithmParams_allOptions( this )
        paramProperties = this.algorithmParamsProperties();
        R = this.createParameterStructures( paramProperties);
    end
    
    %% evaluationParams_allOptions
    
	function R = evaluationParams_allOptions( this )
        paramProperties = this.evaluationParamsProperties();
        R = this.createParameterStructures( paramProperties);
    end
    
end % methods (Access = public)
    
methods (Static)
    %% createParameterStructures
    
    function R = createParameterStructures(paramProperties)
        
        paramsVector = ParamsManager.createParamsVector( paramProperties );
        
        numParams = length(paramProperties);
        numStructs = size(paramsVector ,1);
        paramStructs = [];
        
        for struct_i=1:numStructs
            new = [];
            for param_i=1:numParams
                isString   = paramProperties(param_i).isString;
                paramName  = paramProperties(param_i).name;
                if (0 == isString)
                    paramValue = paramsVector   (struct_i, param_i);
                else
                    paramNumericValue = paramsVector   (struct_i, param_i);
                    paramValue        = paramProperties(param_i).values(paramNumericValue);
                end
                new.(paramName) = paramValue ;
            end
            paramStructs = [paramStructs; new]; %#ok<AGROW>
        end
        R = paramStructs;
    end

    %% createParamsVector
    
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

