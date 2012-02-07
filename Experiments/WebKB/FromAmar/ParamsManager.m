classdef ParamsManager < handle
    %PARAMSMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
properties (GetAccess = public, SetAccess = private)
    m_K;
    m_alpha;
    m_beta;
    m_labeledConfidence;
    m_mu1;
    m_mu2;
    m_mu3;
    m_makeSymetric;
    m_maxIterations;
    m_numLabeled;
    m_numFolds;
    m_numInstancesPerClass; % is required ?
    m_useGraphHeuristics;
    m_fileName;
    m_numEvaluationRuns;
    m_labeledInitMode;
    m_balancedFolds;
    m_balancedLabeled;
end

properties( Constant)
    % unlabeled:0 
    % labeled: +1 - belong to class,
    %           0 does not belong to class.
    LABELED_INIT_ZERO_ONE = 1;
    % unlabeled:0 
    % labeled: +1 - belong to class,
    %          -1 does not belong to class.
    LABELED_INIT_MINUS_PLUS_ONE = 2;
    % unlabeled:-1
    % labeled: +1 - belong to class,
    %          -1 does not belong to class.
    LABELED_INIT_MINUS_PLUS_ONE_UNLABELED = 3;
    
    SAVE_ALL_ITERATIONS_IN_RESULT = 0;
end
    
methods (Access = public)
    function this = ParamsManager(isOnOdin) %constructor        
        
        isString = 1;
        if isOnOdin
            fileNames = [ {'/u/matanorb/experiments/webkb/data/Rapid_Miner_Result/webkb_constructed.mat' } ];
        else
            fileNames = [ {'C:\technion\theses\Experiments\WebKB\data\Rapid_Miner_Result\webkb_constructed.mat'}];
        end
        this = this.createParameter( 'fileName', [1] , isString, fileNames );
        
        isString = 0;
        this = this.createParameter(  'K', [1000], isString, [] );
        %K.range = [1,2,5,10,20,50,100,500];
        
        %alpha.range = [0.0001, 0.001, 0.01,0.1,1];
        %alpha.range = [10^(-5), 10^(-4), 0.001, 0.01,  1, 10^2, 10^4 ];
        this = this.createParameter( 'alpha', [1], isString, [] );
        
        %beta.range = [1,10, 100,1000,10000];
        %beta.range = [10, 100, 10^3, 10^4,10^5, 10^6, 10^7, 10^8];
        %beta.range = [10^(-5), 10^(-4), 0.001, 0.01, 1, 10^2, 10^4 ];
        this = this.createParameter( 'beta', [1], isString, [] );
        
        paperOprimizationRange = [1e-8 1e-4 1e-2 1 10 1e2 1e3];
        this = this.createParameter( 'mu1', [1], isString, [] );     
%          this = this.createParameter( 'mu2', paperOprimizationRange, isString, [] );  
%          this = this.createParameter( 'mu3', paperOprimizationRange, isString, [] );
        this = this.createParameter( 'mu2', [1], isString, [] );     
        this = this.createParameter( 'mu3', [1], isString, [] );
        
        %labeledConfidence.range = [0.01,0.1];
        this = this.createParameter( 'labeledConfidence', [1], isString, [] );     
        
        this = this.createParameter( 'makeSymetric', [1], isString, [] );     
        
        %numIterations.range = [5 10 25 50 100];
        this = this.createParameter( 'maxIterations', [3], isString, [] );    
        
        this = this.createParameter( 'numLabeled', [48], isString, [] );    
        
        this = this.createParameter( 'numFolds', [4], isString, [] );    
        
        % 0 means all instances
        this = this.createParameter( 'numInstancesPerClass', [0], isString, [] );    
        
        this = this.createParameter( 'useGraphHeuristics', [0 1], isString, [] );
        
        this = this.createParameter( 'numEvaluationRuns', [1], isString, [] );
        
        this = this.createParameter( 'labeledInitMode', ...
            [ParamsManager.LABELED_INIT_ZERO_ONE], isString, [] );
        
        this = this.createParameter( 'balancedFolds',   [1], isString, [] );
        this = this.createParameter( 'balancedLabeled', [1], isString, [] );
        
    end
    
    %% createParameter
    
    function this = createParameter( this, name, range , isString, strValues)
        memebrName = ['m_' name];
        this.(memebrName).range = range;
        this.(memebrName).name = name;
        this.(memebrName).isString = isString;
        this.(memebrName).values = strValues;
    end
    
    %% evaluationParamsProperties
    function R = evaluationParamsProperties(this)
        R = [ this.m_makeSymetric,       this.m_maxIterations, ...
              this.m_useGraphHeuristics, this.m_labeledInitMode, ...
              this.m_numEvaluationRuns,  this.m_balancedLabeled, ...
              this.m_balancedFolds];
    end   
    
    %% constructionParamsProperties
    
    function R = constructionParamsProperties(this)
        %this.m_numInstancesPerClass,
        R = [  this.m_fileName, this.m_K, this.m_numLabeled, this.m_numFolds];
    end
    
    %% optimizationParamsCSSL
    
    function R = optimizationParamsCSSL(this)
        R = [ this.m_alpha, this.m_beta, this.m_labeledConfidence];
    end
    
    %% optimizationParamsMAD
    function R = optimizationParamsMAD(this)
        R = [ this.m_mu1, this.m_mu2, this.m_mu3 ];
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
    
    %% evaluationParams_allOptions
    
	function R = evaluationParams_allOptions( this )
        paramProperties = this.evaluationParamsProperties();
        R = this.createParameterStructures( paramProperties);
    end
    
end % methods (Access = public)
    
methods (Static)
    %% addParamsToCollection
    
    function R = addParamsToCollection(optionsCollection, paramsToAdd)
        numOptions = length(optionsCollection);
        for option_i=1:numOptions
            currentOption = optionsCollection(option_i);
            %http://stackoverflow.com/questions/38645/what-are-some-efficient-ways-to-combine-two-structures-in-matlab
            M = [fieldnames(currentOption)' fieldnames(paramsToAdd)'; ...
                 struct2cell(currentOption)' struct2cell(paramsToAdd)'];
            R(option_i)=struct(M{:}); %#ok<AGROW>
        end
    end
    
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
                    paramValue        = paramProperties(param_i).values{paramNumericValue};
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

