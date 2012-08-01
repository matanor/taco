classdef ParamsManager < handle
    %PARAMSMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
properties (GetAccess = public, SetAccess = private)
    m_K;
    m_alpha;
    m_beta;
    m_zeta;
    m_isUsingStructured;
    m_labeledConfidence;
    m_isUsingL2Regularization;
    m_isUsingSecondOrder;
    m_mu1;
    m_mu2;
    m_mu3;
    m_mad_K;
    m_am_v;
    m_am_mu;
    m_am_K;
    m_am_alpha;
    m_makeSymetric;
    m_maxIterations;
    m_numLabeled;
    m_numFolds;
    m_useGraphHeuristics;
    m_fileProperties;
    m_numEvaluationRuns;
    m_labeledInitMode;
    m_balanced;
    m_optimizeByCollection;
    m_defaultParamsCSSL;
    m_defaultParamsMAD;
    m_defaultParamsAM;
    m_isCalculateKNN;
    m_descendMethodCSSL;
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
    
end

properties (Constant)
    SAVE_ALL_ITERATIONS_IN_RESULT = 0;
    REAL_RANDOMIZATION = 0;
    CLEAR_ALGORITHM_OUTPUT = 1;
end

properties (Constant)
    ASYNC_RUNS = 0;
end

properties (Constant)
    OPTIMIZE_BY_ACCURACY = 1;
    OPTIMIZE_BY_PRBEP = 2;
    OPTIMIZE_ALL_1 = 3;
    OPTIMIZE_BY_MRR = 4;
    OPTIMIZE_BY_MACRO_MRR = 5;
    OPTIMIZE_BY_MACRO_ACCURACY = 6;
    OPTIMIZE_BY_LEVENSHTEIN = 7;
end

methods (Access = public)
    function this = ParamsManager() %constructor        
        
        isTesting = 1;
        optimize = ~isTesting;
        
        configManager = ConfigManager.get();
        config = configManager.read();

        if config.isOnOdin
            rootDir = '/u/matanorb/experiments/';
        else
            rootDir = 'C:/technion/theses/Experiments/';            
        end
        
        useTFIDF = 1;
        if useTFIDF
            tfidf = '.tfidf';
        else
            tfidf = [];
        end
        
        webkb_constructed    = [ rootDir 'webkb/data/Rapid_Miner_Result/webkb_constructed.mat'];
        webkb_amar           = [ rootDir 'webkb/data/from_amar/webkb_amar.mat'];
        webkb_html           = [ rootDir 'webkb/data/With_Html/webkb_with_html.mat'];
        sentiment_5k         = [ rootDir 'sentiment/data/from_yoav/sentiment_5k.mat'];
        sentiment_10k        = [ rootDir 'sentiment/data/from_yoav/sentiment_10k.mat'];
        twentyNG_4715        = [ rootDir '20NG/data/twentyNG_4715.mat'];
        twentyNG_18828       = [ rootDir '20NG/18828/twentyNG'          tfidf '.graph.mat'];
        enronFarmer          = [ rootDir 'enron/farmer/farmer-d'        tfidf '.graph.mat'];
        enronKaminski        = [ rootDir 'enron/kaminski/kaminski-v'    tfidf '.graph.mat'];
        amazon3              = [ rootDir 'amazon/books_dvd_music/books_dvd_music' tfidf '.graph.mat'];
        amazon7              = [ rootDir 'amazon/all/all'               tfidf '.graph.mat'];
        reuters              = [ rootDir 'reuters/reuters_4_topics'     tfidf '.graph.mat'];
        phon_synth_context1  = [ rootDir 'StructureSynthetic/data/context_1.mat' ];
        phon_synth_context7  = [ rootDir 'StructureSynthetic/data/context_7.mat' ];
        dummy_timit          = [ rootDir 'timit/dummy.mat' ];
        trainAndDev_timit    = [ rootDir 'timit/trainAndDev/trainAndDev.k_10.mat' ];
        trainAndDev_timit_scaled = [ rootDir 'timit/trainAndDev/trainAndDev.k_10.scaled.mat' ];
        trainAndDev_timit_scaled_identity   = [ rootDir 'timit/trainAndDev/trainAndDev.k_10.scaled.identity.mat' ];
        trainAndDev_timit_not_white         = [ rootDir 'timit/trainAndDev_notWhitenedFeatures/train_and_dev_not_white.context_7_whitened.k_10.mat' ];
        trainAndDev_notWhite_c7_alex = [ rootDir 'timit/features_39_trainAndDev/trainAndDev_notWhite.context7.k_10.alex.mat' ];
        trainAndDev_notWhite_c7_lihi = [ rootDir 'timit/features_39_trainAndDev/trainAndDev_notWhite.context7.k_10.lihi.mat' ];
        trainAndDev_notWhite_alex    = [ rootDir 'timit/features_39_trainAndDev/trainAndDev_notWhite.k_10.alex.mat' ];
        trainAndDev_notWhite_lihi    = [ rootDir 'timit/features_39_trainAndDev/trainAndDev_notWhite.k_10.lihi.mat' ];
        
        trainAndTest_notWhite_c7_alex = [ rootDir 'timit/features_39_trainAndTest/trainAndTest_notWhite.context7.k_10.alex.mat' ];
        trainAndTest_notWhite_c7_lihi = [ rootDir 'timit/features_39_trainAndTest/trainAndTest_notWhite.context7.k_10.lihi.mat' ];
        trainAndTest_notWhite_alex    = [ rootDir 'timit/features_39_trainAndTest/trainAndTest_notWhite.k_10.alex.mat' ];
        trainAndTest_notWhite_lihi    = [ rootDir 'timit/features_39_trainAndTest/trainAndTest_notWhite.k_10.lihi.mat' ];
        
        timit_notWhite_c7_alex.development = [ rootDir 'timit/features_39/trainAndDev/trainAndDev_notWhite.context7.k_10.alex.mat' ];
        timit_notWhite_c7_alex.test        = [ rootDir 'timit/features_39/trainAndTest/trainAndTest_notWhite.context7.k_10.alex.mat' ];
        timit_notWhite_c7_alex.transductionSetFilePath = [ rootDir 'timit/features_39/notWhite.TrunsSet_001.mat' ];

        if config.isOnOdin
           fileProperties = [ {timit_notWhite_c7_alex} ...
                         ];
%                          {webkb_amar} ...
%                          {webkb_html} ...
%                          {sentiment_5k} ...
%                          {sentiment_10k} ...
%                          {twentyNG_4715} ];
        else
           fileProperties  = [ {timit_notWhite_c7_alex} ...
                         ];
%                          {webkb_html} ...
%                          {sentiment_5k} ...
%                          {sentiment_10k} ...
%                          {twentyNG_4715} ];
        end
        filePropertiesRange = 1:length(fileProperties );
        
        isNumeric = 0;
        this = this.createParameter( 'fileProperties', filePropertiesRange , ...
                                     isNumeric, fileProperties );
                                 
        if (optimize)
%             kOptimizationRange = [100 500 1000 2000];
            kOptimizationRange = [1];
            this = this.createNumericParameter(  'K', kOptimizationRange );
        else
            this = this.createNumericParameter(  'K', [1000] );
        end
        %K.range = [1,2,5,10,20,50,100,500];
        
        %alpha.range = [0.0001, 0.001, 0.01,0.1,1];
        %alpha.range = [10^(-5), 10^(-4), 0.001, 0.01,  1, 10^2, 10^4 ];
                %beta.range = [1,10, 100,1000,10000];
        %beta.range = [10, 100, 10^3, 10^4,10^5, 10^6, 10^7, 10^8];
        %beta.range = [10^(-5), 10^(-4), 0.001, 0.01, 1, 10^2, 10^4 ];
        %labeledConfidence.range = [0.01,0.1];
        if (optimize)
            alphaOptimizationRange = [1e-4 1e-2 1 1e2 ];
            betaOptimizationRange  = [1e-4 1e-2 1 1e2 ];
            zetaOptimizationRange  = [1 10 100];
            gammaOptimizationRange = [1 5];

            this = this.createNumericParameter( 'alpha', alphaOptimizationRange );
            this = this.createNumericParameter( 'beta',  betaOptimizationRange );
            this = this.createNumericParameter( 'labeledConfidence', gammaOptimizationRange );
            this = this.createNumericParameter( 'zeta',  zetaOptimizationRange );
        else
            this = this.createNumericParameter( 'alpha', [1] );
            this = this.createNumericParameter( 'beta' , [1 ] );        
            this = this.createNumericParameter( 'labeledConfidence', [1] );     
            this = this.createNumericParameter( 'zeta',  [0] );
        end
        
        this = this.createNumericParameter( 'isUsingL2Regularization', [0] );
        
        if isTesting
            this = this.createNumericParameter( 'isUsingSecondOrder', [1] );
        else 
            this = this.createNumericParameter( 'isUsingSecondOrder', [1] );
        end
        
        if isTesting
            this = this.createNumericParameter( 'isCalculateKNN',    [0] );
        else
            this = this.createNumericParameter( 'isCalculateKNN',    [0] );
        end
        
        if isTesting
            this = this.createNumericParameter( 'isUsingStructured',    [0] );
        else
            this = this.createNumericParameter( 'isUsingStructured',    [0] );
        end
        
        this = this.createNumericParameter( 'descendMethodCSSL', ...
                                     [CSSLBase.DESCEND_MODE_COORIDNATE_DESCENT] );
        
        this.m_defaultParamsCSSL.K = 1000;
        this.m_defaultParamsCSSL.alpha = 1;
        this.m_defaultParamsCSSL.beta = 1;
        this.m_defaultParamsCSSL.zeta = 1;
        this.m_defaultParamsCSSL.labeledConfidence = 1;
        
        this = this.createNumericParameter( 'mu1', [1] );
        if (optimize)
            paperOprimizationRange = [1e-8 1e-4 1e-2 1 10 1e2 1e3];        
            this = this.createNumericParameter( 'mu2', paperOprimizationRange );  
            this = this.createNumericParameter( 'mu3', paperOprimizationRange );
            mad_k_paper_range = [10,50,100,500,1000,2000];
            this = this.createNumericParameter...
                ( 'mad_K',   kOptimizationRange  ); % NO all vertices option
        else
            this = this.createNumericParameter( 'mu2', [1] );     
            this = this.createNumericParameter( 'mu3', [1] );
            this = this.createNumericParameter...
                ( 'mad_K',     [1000]); % NO all vertices option
        end
        
        this.m_defaultParamsMAD.K = 1000;
        this.m_defaultParamsMAD.mu1 = 1;
        this.m_defaultParamsMAD.mu2 = 1;
        this.m_defaultParamsMAD.mu3 = 1;
        
        if (optimize)
            this = this.createNumericParameter...
                ( 'am_v',     [1e-8 1e-6 1e-4 0.01 0.1 ]);
            this = this.createNumericParameter...
                ( 'am_mu',    [1e-8 1e-4 0.01 0.1 1 10 100]);
            this = this.createNumericParameter( 'am_alpha', [2]);
            am_k_range_paper = [2,10,50,100,250,500,1000,2000]; % NO all vertices option
            this = this.createNumericParameter...
                ( 'am_K',     kOptimizationRange); 
        else
            this = this.createNumericParameter( 'am_v',     [1e-4]);
            this = this.createNumericParameter( 'am_mu',    [1e-2]);
            this = this.createNumericParameter( 'am_alpha', [2]);
            this = this.createNumericParameter( 'am_K',     [1000]);
        end
        
        this.m_defaultParamsAM.K = 1000;
        this.m_defaultParamsAM.am_v = 1e-4;
        this.m_defaultParamsAM.am_mu = 1e-2;
        this.m_defaultParamsAM.am_alpha = 2;
        
        this = this.createNumericParameter( 'makeSymetric', [1] );     
        
        if isTesting
            this = this.createNumericParameter( 'maxIterations', [1] );    
            this = this.createNumericParameter( 'numEvaluationRuns', [1] );
        else
            this = this.createNumericParameter( 'maxIterations',     [20] );    
            this = this.createNumericParameter( 'numEvaluationRuns', [1] );
        end
        
        if isTesting
            this = this.createNumericParameter( 'numLabeled', [11147] );    
        else
            this = this.createNumericParameter( 'numLabeled', [111133] );    
        end
        %11101 - 0.01% (dev)
        %110606 - 0.1% (dev)
%11147 - 0.01% (test)
%111133 - 0.01% (test)
        %11411 - no
        %1105455 - no
        
        if isTesting
            this = this.createNumericParameter( 'numFolds', [1] );    
        else
            this = this.createNumericParameter( 'numFolds', [1] );    
        end
        
        if isTesting
            this = this.createNumericParameter( 'useGraphHeuristics', [0] );
        else 
            this = this.createNumericParameter( 'useGraphHeuristics', [0] );
        end
        
        if isTesting
            this = this.createNumericParameter( 'labeledInitMode', ...
                [ParamsManager.LABELED_INIT_ZERO_ONE] );
        else
            this = this.createNumericParameter( 'labeledInitMode', ...
                 [ ParamsManager.LABELED_INIT_ZERO_ONE ] );
        end
        
        if isTesting
            this = this.createNumericParameter( 'balanced', [0] );
        else
            this = this.createNumericParameter( 'balanced', [0] );
        end
        
        if isTesting
            this = this.createNumericParameter( 'optimizeByCollection', ...
                [ParamsManager.OPTIMIZE_BY_ACCURACY] );
        else
            this = this.createNumericParameter( 'optimizeByCollection', ...
                [ParamsManager.OPTIMIZE_BY_ACCURACY ...
                 ParamsManager.OPTIMIZE_BY_PRBEP ...
                 ParamsManager.OPTIMIZE_ALL_1 ...
                 ParamsManager.OPTIMIZE_BY_MRR...
                 ParamsManager.OPTIMIZE_BY_MACRO_MRR ...
                 ParamsManager.OPTIMIZE_BY_MACRO_ACCURACY ...
                 ParamsManager.OPTIMIZE_BY_LEVENSHTEIN] );
        end
    end
    
    %% algorithmsToRun

    function R = algorithmsToRun(~)
        R = AlgorithmsCollection;
%         R.setRun(SingleRun.MAD);
        R.setRun(SingleRun.CSSLMC);
%         R.setRun(SingleRun.CSSLMCF);
%         R.setRun(SingleRun.AM);
    end
    
    %% createNumericParameter
    
    function this = createNumericParameter(this, name, range)
        isNumeric = 1;
        this = this.createParameter(name, range, isNumeric, []);
    end
    
    %% createParameter
    
    function this = createParameter( this, name, range , isNumeric, nonNumericValues)
        memebrName = ['m_' name];
        if (1 == strcmp(name, 'am_K') || ...
            1 == strcmp(name, 'mad_K') )
            name = 'K';
        end
        this.(memebrName).range = range;
        this.(memebrName).name = name;
        this.(memebrName).isNumeric = isNumeric;
        this.(memebrName).values = nonNumericValues;
    end
    
    %% commonEvaluationParamsProperties
    function R = commonEvaluationParamsProperties(this)
        R = [this.m_optimizeByCollection];
    end
    
    %% evaluationParamsProperties
    function R = evaluationParamsProperties(this)
        R = [ this.m_makeSymetric,       this.m_maxIterations, ...
              this.m_useGraphHeuristics, this.m_labeledInitMode, ...
              this.m_numEvaluationRuns,  this.m_isUsingL2Regularization...
              this.m_isUsingSecondOrder, this.m_isUsingStructured, ...
              this.m_isCalculateKNN,     this.m_descendMethodCSSL];
    end   
    
    %% constructionParamsProperties
    
    function R = constructionParamsProperties(this)
        R = [  this.m_fileProperties,   this.m_numLabeled, ...
               this.m_numFolds,         this.m_balanced, ...
               this.m_numEvaluationRuns];
    end
    
    %% optimizationParamsCSSL
    
    function R = optimizationParamsCSSL(this)
        R = [ this.m_K, this.m_alpha, this.m_beta, this.m_labeledConfidence, this.m_zeta];
    end
    
    %% defaultParamsCSSL
    
    function R = defaultParamsCSSL(this)
        R = this.m_defaultParamsCSSL;
    end
    
    %% optimizationParamsMAD
    function R = optimizationParamsMAD(this)
        R = [ this.m_mad_K, this.m_mu1, this.m_mu2, this.m_mu3 ];
    end  
    
    %% optimizationParamsAM
    
    function R = optimizationParamsAM(this)
        R = [ this.m_am_K, this.m_am_v, this.m_am_mu, this.m_am_alpha ];
    end
    
    %% defaultParamsMAD
    
    function R = defaultParamsMAD(this)
        R = this.m_defaultParamsMAD;
    end
    
    %% defaulPatamsAM
    
    function R = defaultParamsAM(this)
        R = this.m_defaultParamsAM;
    end
    
    %% optimizationParams_allOptions

    function R = optimizationParams_allOptions(this, algorithmType)
        if (SingleRun.CSSLMC == algorithmType || SingleRun.CSSLMCF == algorithmType)
            optimizationParamProperties = this.optimizationParamsCSSL();
        elseif (SingleRun.MAD == algorithmType)
            optimizationParamProperties = this.optimizationParamsMAD();
        elseif (SingleRun.AM == algorithmType)
            optimizationParamProperties = this.optimizationParamsAM();
        else
           Logger.log([ 'Error: not parameter to optimize for algorithm' num2str(algorithmType) ]);
        end
        R = this.createParameterStructures( optimizationParamProperties );
    end
        
    %% shouldOptimize
    
    function R = shouldOptimize(this, algorithmType, optimization_method_i)
        if optimization_method_i ~= ParamsManager.OPTIMIZE_ALL_1
            numOptimizationOptions = length(this.optimizationParams_allOptions(algorithmType) );
            R = (numOptimizationOptions > 1);
        else
            R = 0;
        end
    end
    
    %% defaultParams
    
    function R = defaultParams(this, algorithmType, optimization_method_i)
        R = [];
        if optimization_method_i == ParamsManager.OPTIMIZE_ALL_1
            if (SingleRun.CSSLMC == algorithmType || SingleRun.CSSLMCF == algorithmType)
                R = this.defaultParamsCSSL();
            elseif (SingleRun.MAD == algorithmType)
                R = this.defaultParamsMAD();
            elseif (SingleRun.AM == algorithmType)
                R = this.defaultParamsAM();
            else
               Logger.log([ 'Error: no default parameter for algorithm' num2str(algorithmType) ]);
            end
        else
            R = this.optimizationParams_allOptions(algorithmType);
        end
    end
    
    %% constructionParams_allOptions
    
    function R = constructionParams_allOptions( this )
        paramProperties = this.constructionParamsProperties();
        R = this.createParameterStructures( paramProperties);
    end
    
    %% parameterValues_allOptions
    
	function R = parameterValues_allOptions( this )
        paramProperties = this.evaluationParamsProperties();
        evaluationParams = this.createParameterStructures( paramProperties );
        commonParamProperties = this.commonEvaluationParamsProperties();
        for option_i=1:length(evaluationParams)
            for common_param_i=1:length(commonParamProperties)
                isNumeric   = commonParamProperties(common_param_i).isNumeric;
                paramName  = commonParamProperties(common_param_i).name;
                if 0 == isNumeric
                    paramValue = commonParamProperties(common_param_i).values;
                else
                    paramValue = commonParamProperties(common_param_i).range;
                end
                evaluationParams(option_i).(paramName) = paramValue;
            end
        end
        R = evaluationParams;
    end
    
end % methods (Access = public)
    
methods (Static)
    %% addParamsToCollection
    
    function R = addParamsToCollection(optionsCollection, paramsToAdd)
        numOptions = length(optionsCollection);
        for option_i=1:numOptions
            currentOption = optionsCollection(option_i);
            R(option_i) = Utilities.combineStructs(currentOption, paramsToAdd); %#ok<AGROW>
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
                isNumeric  = paramProperties(param_i).isNumeric;
                paramName  = paramProperties(param_i).name;
                if (1 == isNumeric)
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

