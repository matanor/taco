classdef ParamsManager < handle
    %PARAMSMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
properties (GetAccess = public, SetAccess = private)
    m_K;
    m_alpha;
    m_beta;
    m_zeta;
    m_structuredTermType;
    m_csslObjectiveType;
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
    m_qc_K;
    m_qc_mu2;
    m_qc_mu3;
    m_makeSymetric;
    m_maxIterations;
    m_precentLabeled;
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
    m_defaultParamsQC;
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
    WEBKB_CONSTRUCTED = 5;
    TWENTY_NG_4715    = 6;
    ENRON_FARMER      = 7;
    ENRON_KAMINSKI    = 8;
    REUTERS           = 9;
    AMAZON_3          = 10;
    SENTIMENT_5K      = 11;
    AMAZON_7          = 12;
    TIMIT_CMS_WHITE_C7_ALEX = 13;
    TIMIT_CMS_WHITE_C7_LIHI = 14;
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
        
        webkbGraphPath          = [ rootDir 'webkb/data/Rapid_Miner_Result/webkb_constructed.mat'];
        twentyNG_4715_graphPath = [ rootDir '20NG/data/twentyNG_4715.mat'];
        enronFarmerGraphPath    = [ rootDir 'enron/farmer/farmer-d'                  tfidf '.graph.mat'];
        enronKaminskiGraphPath  = [ rootDir 'enron/kaminski/kaminski-v'                  tfidf '.graph.mat'];
        amazon3graphPath        = [ rootDir 'amazon/books_dvd_music/books_dvd_music' tfidf '.graph.mat'];
        amazon7graphPath        = [ rootDir 'amazon/all/all'                         tfidf '.graph.mat'];
        reutersGraphPath        = [ rootDir 'reuters/reuters_4_topics'               tfidf '.graph.mat'];
        sentiment_5kGraphPath   = [ rootDir 'sentiment/data/from_yoav/sentiment_5k.mat'];

        webkb_amar           = [ rootDir 'webkb/data/from_amar/webkb_amar.mat'];
        webkb_html           = [ rootDir 'webkb/data/With_Html/webkb_with_html.mat'];
        sentiment_10k        = [ rootDir 'sentiment/data/from_yoav/sentiment_10k.mat'];
        twentyNG_18828       = [ rootDir '20NG/18828/twentyNG'          tfidf '.graph.mat'];
        
        webkb_constructed = this.createTextDataset(webkbGraphPath,          ParamsManager.WEBKB_CONSTRUCTED);
        twentyNG_4715     = this.createTextDataset(twentyNG_4715_graphPath, ParamsManager.TWENTY_NG_4715);
        enronFarmer       = this.createTextDataset(enronFarmerGraphPath,    ParamsManager.ENRON_FARMER);
        enronKaminski     = this.createTextDataset(enronKaminskiGraphPath,  ParamsManager.ENRON_KAMINSKI);
        amazon3           = this.createTextDataset(amazon3graphPath,        ParamsManager.AMAZON_3);
        amazon7           = this.createTextDataset(amazon7graphPath,        ParamsManager.AMAZON_7);
        reuters           = this.createTextDataset(reutersGraphPath,        ParamsManager.REUTERS);
        sentiment_5k      = this.createTextDataset(sentiment_5kGraphPath,   ParamsManager.SENTIMENT_5K);

        allTextDataSets = [ {webkb_constructed}, {twentyNG_4715}, {enronFarmer}, ...
                            {enronKaminski},     {amazon3},       {reuters}, ...
                            {sentiment_5k} ];
        
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
        
        notWhite_transduction_file = [ rootDir 'timit/features_39/notWhite.TrunsSet_%s.mat' ];
        cms_white_transduction_file_format = [ rootDir 'timit/features_39_cms_white/cms_white.TrunsSet_%s.mat' ];
        
        timit_notWhite_c7_alex.development = [ rootDir 'timit/features_39/trainAndDev/trainAndDev_notWhite.context7.k_10.alex.mat' ];
        timit_notWhite_c7_alex.test        = [ rootDir 'timit/features_39/trainAndTest/trainAndTest_notWhite.context7.k_10.alex.mat' ];
        timit_notWhite_c7_alex.transductionSetFileFormat = notWhite_transduction_file;
        
        timit_cms_white_c7_alex_development = 'timit/features_39_cms_white/trainAndDev/trainAndDev_cms_white.context7.k_10.alex.mat';
        timit_cms_white_c7_alex_test        = 'timit/features_39_cms_white/trainAndTest/trainAndTest_cms_white.context7.k_10.alex.mat' ;
        timit_cms_white_c7_alex = this.createSpeechDataSet                  ...
                                    (rootDir,                               ...
                                     timit_cms_white_c7_alex_development,   ...
                                     timit_cms_white_c7_alex_test,          ...
                                     ParamsManager.TIMIT_CMS_WHITE_C7_ALEX);                
        
        timit_cms_white_c7_lihi_development = 'timit/features_39_cms_white/trainAndDev/trainAndDev_cms_white.context7.k_10.lihi.mat';
        timit_cms_white_c7_lihi_test        = 'timit/features_39_cms_white/trainAndTest/trainAndTest_cms_white.context7.k_10.lihi.mat';
        timit_cms_white_c7_lihi = this.createSpeechDataSet                  ...
                                    (rootDir,                               ...
                                     timit_cms_white_c7_lihi_development,   ...
                                     timit_cms_white_c7_lihi_test,          ...
                                     ParamsManager.TIMIT_CMS_WHITE_C7_LIHI);        

        timit_cms_white_alex.development = [ rootDir 'timit/features_39_cms_white/trainAndDev/trainAndDev_cms_white.k_10.alex.mat' ];
        timit_cms_white_alex.test        = [ rootDir 'timit/features_39_cms_white/trainAndTest/trainAndTest_cms_white.k_10.alex.mat' ];
        timit_cms_white_alex.transductionSetFileFormat = cms_white_transduction_file_format;
        
        timit_cms_white_lihi.development = [ rootDir 'timit/features_39_cms_white/trainAndDev/trainAndDev_cms_white.k_10.lihi.mat' ];
        timit_cms_white_lihi.test        = [ rootDir 'timit/features_39_cms_white/trainAndTest/trainAndTest_cms_white.k_10.lihi.mat' ];
        timit_cms_white_lihi.transductionSetFileFormat = cms_white_transduction_file_format;

        vj_v4_w1 = this.createVJdataset(rootDir, 'v4.w1', VJGenerator.V4_W1);
        vj_v4_w7 = this.createVJdataset(rootDir, 'v4.w7', VJGenerator.V4_W7);
        vj_v8_w1 = this.createVJdataset(rootDir, 'v8.w1', VJGenerator.V8_W1);
        vj_v8_w7 = this.createVJdataset(rootDir, 'v8.w7', VJGenerator.V8_W7);

        if config.isOnOdin
           fileProperties = [ {timit_cms_white_c7_alex} ...
                              {timit_cms_white_c7_lihi} ...
                              {timit_cms_white_alex} ...
                              {timit_cms_white_lihi} ...
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
            kOptimizationRange.text = [100 500 1000 2000];
            kOptimizationRange.speech = [10];
            this = this.createNumericParameter(  'K', kOptimizationRange.text );
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
            alphaOptimizationRange.speech = [1e-4 1e-2 1 1e2 1e4 ];
            alphaOptimizationRange.text   = [1e-8 1e-4 1e-2 1 10 100 ];
            betaOptimizationRange.speech  = [1e-4 1e-2 1 1e2 ];
            betaOptimizationRange.text  = [1e-8 1e-4 1e-2 1 10 100 ];
            zetaOptimizationRange  = [0];
            gammaOptimizationRange.speech = [1 100];
            gammaOptimizationRange.text = [1 2 5];

            this = this.createNumericParameter( 'alpha',             ...
                                                alphaOptimizationRange.text );
            this = this.createNumericParameter( 'beta',              ...
                                                betaOptimizationRange.text );
            this = this.createNumericParameter( 'labeledConfidence', ...
                                                gammaOptimizationRange.text );
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
            this = this.createNumericParameter( 'structuredTermType',  ...
                [CSSLBase.NO_STRUCTURED_TERM] );
        else
            this = this.createNumericParameter( 'structuredTermType',  ...
                [CSSLBase.NO_STRUCTURED_TERM] );
        end
        
        if isTesting
            this = this.createNumericParameter( 'csslObjectiveType',  ...
                [CSSLBase.OBJECTIVE_HARMONIC_MEAN] );
        else
            this = this.createNumericParameter( 'csslObjectiveType',  ...
                [CSSLBase.OBJECTIVE_HARMONIC_MEAN] );
        end
        
        this = this.createNumericParameter( 'descendMethodCSSL', ...
                                     [CSSLBase.DESCEND_MODE_COORIDNATE_DESCENT] );
        
        this.m_defaultParamsCSSL.K = 1000;
        this.m_defaultParamsCSSL.alpha = 1;
        this.m_defaultParamsCSSL.beta = 1;
        this.m_defaultParamsCSSL.zeta = 0;
        this.m_defaultParamsCSSL.labeledConfidence = 1;
        
        this = this.createNumericParameter( 'mu1', [1] );
        if (optimize)
            paperOprimizationRange = [1e-8 1e-4 1e-2 1 10 1e2 1e3];        
            this = this.createNumericParameter( 'mu2', paperOprimizationRange );  
            this = this.createNumericParameter( 'mu3', paperOprimizationRange );
            mad_k_paper_range = [10,50,100,500,1000,2000];
            this = this.createNumericParameter...
                ( 'mad_K',   kOptimizationRange.text  ); % NO all vertices option
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
            this = this.createNumericParameter( 'am_alpha', [1]);
            am_k_range_paper = [2,10,50,100,250,500,1000,2000]; % NO all vertices option
            this = this.createNumericParameter...
                ( 'am_K',     kOptimizationRange.text); 
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
        
        if (optimize)
            this = this.createNumericParameter...
                ( 'qc_mu2',    [1e-8 1e-4 0.01 0.1 1 10 100]);
            this = this.createNumericParameter...
                ( 'qc_mu3',    [1e-8 1e-4 0.01 0.1 1 10 100]);
            this = this.createNumericParameter...
                ( 'qc_K',     kOptimizationRange.text); 
        else
            this = this.createNumericParameter( 'qc_mu2',   [1]);
            this = this.createNumericParameter( 'qc_mu3',   [1]);
            this = this.createNumericParameter( 'qc_K',     [2000]);
        end
        
        this.m_defaultParamsQC.K = 1000;
        this.m_defaultParamsQC.qc_mu2 = 1;
        this.m_defaultParamsQC.qc_mu3 = 1;
        
        this = this.createNumericParameter( 'makeSymetric', [1] );     
        
        if isTesting
            this = this.createNumericParameter( 'maxIterations', [1] );    
            this = this.createNumericParameter( 'numEvaluationRuns', [1] );
        else
            this = this.createNumericParameter( 'maxIterations',     [20] );    
            this = this.createNumericParameter( 'numEvaluationRuns', [1] );
        end
        
        if isTesting
            this = this.createNumericParameter( 'precentLabeled', [1] );    
            % select 1% for text
        else
            this = this.createNumericParameter( 'precentLabeled', [1] );    
%            webkb:  0.1, 1,   2.5,    5,   10,
        end
        %11101 - 0.01% (dev)
        %110606 - 0.1% (dev)
%11147 - 0.01% (test)
%55456 - 0.05% (test)
%111133 - 0.1% (test)
%221254 - 0.2% (test)
%331793 - 0.3% (test)
%553041 - 0.5% (test)
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
%         R.setRun(SingleRun.QC);
%         R.setRun(SingleRun.CSSLMCF);
        R.setRun(SingleRun.AM);
    end
    
    %% createVJdataset
    
    function R = createVJdataset(this, rootDir, fileIdentifier, datasetID)
        R.development = [ rootDir 'VJ/' fileIdentifier '/trainAndDev/trainAndDev.instances.'   fileIdentifier '.k_10.lihi.mat' ];
        R.test        = [ rootDir 'VJ/' fileIdentifier '/trainAndTest/trainAndTest.instances.' fileIdentifier '.k_10.lihi.mat' ];
        R.transductionSetFileFormat = [ rootDir 'VJ/' fileIdentifier '/' fileIdentifier '.TrunsSet_%s.mat' ];
        R.useNumLabeledToPrecent    = 0;
        R.precentToNumLabeledTable = this.precentToNumLabeledTable(datasetID);
    end
    
    %% createTextDataset
     
    function R = createTextDataset(this, graphFullPath, datasetID)
        R.development    = graphFullPath;
        R.test = [];
        R.transductionSetFileFormat = [];
        R.isCalcPRBEP = 1;
        R.clearAlgorithmOutput = 0;
        R.precentToNumLabeledTable = this.precentToNumLabeledTable(datasetID);
    end
    
    %% createSpeechDataSet
    
    function R = createSpeechDataSet(this, root, devGraphFullPath, testGraphFullPath, datasetID)
        R.development    = [root devGraphFullPath];
        R.test           = [root testGraphFullPath];
        cms_white_transduction_file_format = [ root 'timit/features_39_cms_white/cms_white.TrunsSet_%s.mat' ];
        R.transductionSetFileFormat = cms_white_transduction_file_format;
        R.isCalcPRBEP               = 0;
        R.clearAlgorithmOutput      = 1;
        R.precentToNumLabeledTable  = this.precentToNumLabeledTable(datasetID);
    end    
    
    %% createNumericParameter
    
    function this = createNumericParameter(this, name, range)
        isNumeric = 1;
        this = this.createParameter(name, range, isNumeric, []);
    end
    
    %% createParameter
    
    function this = createParameter( this, name, range , isNumeric, nonNumericValues)
        memebrName = ['m_' name];
        if (1 == strcmp(name,  'am_K')  || ...
            1 == strcmp(name,  'mad_K') || ...
            1 == strcmp(name, 'qc_K')  )
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
        R = [ this.m_makeSymetric,       this.m_maxIterations,          ...
              this.m_useGraphHeuristics, this.m_labeledInitMode,        ...
              this.m_numEvaluationRuns,  this.m_isUsingL2Regularization ...
              this.m_isUsingSecondOrder, this.m_structuredTermType,     ...
              this.m_csslObjectiveType,                                   ...
              this.m_isCalculateKNN,     this.m_descendMethodCSSL];
    end   
    
    %% constructionParamsProperties
    
    function R = constructionParamsProperties(this)
        R = [  this.m_fileProperties,   this.m_precentLabeled, ...
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
    
    %% optimizationParamsQC
    
    function R = optimizationParamsQC(this)
        R = [ this.m_qc_K, this.m_qc_mu2, this.m_qc_mu3 ];
    end
    
    %% defaultParamsMAD
    
    function R = defaultParamsMAD(this)
        R = this.m_defaultParamsMAD;
    end
    
    %% defaultParamsAM
    
    function R = defaultParamsAM(this)
        R = this.m_defaultParamsAM;
    end
    
    %% defaultParamsQC
    
    function R = defaultParamsQC(this)
        R = this.m_defaultParamsQC;
    end
    
    %% optimizationParams_allOptions

    function R = optimizationParams_allOptions(this, algorithmType)
        if (SingleRun.CSSLMC == algorithmType || SingleRun.CSSLMCF == algorithmType)
            optimizationParamProperties = this.optimizationParamsCSSL();
        elseif (SingleRun.MAD == algorithmType)
            optimizationParamProperties = this.optimizationParamsMAD();
        elseif (SingleRun.AM == algorithmType)
            optimizationParamProperties = this.optimizationParamsAM();
        elseif (SingleRun.QC == algorithmType)
            optimizationParamProperties = this.optimizationParamsQC();
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
            elseif (SingleRun.QC == algorithmType)
                R = this.defaultParamsQC();
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
    
    
    %% precentToNumLabeledTable
    %  for speech, transduction sets are common to more than one graph.
    %  so the naming scheme for the transduction sets file name is
    %  different, this function translates from a precentage of labeled frames
    %  in the test graph, to the precent of labeled data used, which is
    %  part of the transduction file name scheme
    
    function R = precentToNumLabeledTable(~, datasetID)
        %                                 0.01, 0.1, 1,   2.5,    5,   10,   20,    30,    50
        numLabeled(VJGenerator.V4_W1,:) = [27   279  2794    0 13974 27948  55896  83845  139742];
        numLabeled(VJGenerator.V4_W7,:) = [26   268  2680    0 13404 26808  53617  80426  134043];
        numLabeled(VJGenerator.V8_W1,:) = [57   572  5729    0 28645 57291 114582 171873 286455];
        numLabeled(VJGenerator.V8_W7,:) = [42   426  4263    0 21315 42630  85260  127890 213150];
        numLabeled(ParamsManager.WEBKB_CONSTRUCTED,:) = ...
                                          [0      24    48    96     192     500      0      0       0];
        numLabeled(ParamsManager.TWENTY_NG_4715,:) = ...
                                          [0      0    105   0     0   500      0      0       0];
        numLabeled(ParamsManager.ENRON_FARMER,:) = ...
                                          [0      0    48  105     0   500      0      0       0];
        numLabeled(ParamsManager.ENRON_KAMINSKI,:) = ...
                                          [0      0    48  105     0   500      0      0       0];
        numLabeled(ParamsManager.REUTERS,:) = ...
                                          [0      0    48    0     0     0       0      0       0];
        numLabeled(ParamsManager.AMAZON_3,:) = ...
                                          [0      0    35  105     0   500      0      0       0];
        numLabeled(ParamsManager.SENTIMENT_5K,:) = ...
                                          [0      0   500  105     0   500      0      0       0];
        numLabeled(ParamsManager.AMAZON_7,:) = ...
                                          [0      0    48  105     0   500      0      0       0];
                                          %0.01, 0.1,      1, 2.5,     5,     10,    20,    30,    50
        numLabeled(ParamsManager.TIMIT_CMS_WHITE_C7_ALEX,:) = ...
                                          [0      0    11147    0  55456  111133 221254 331793  553041];
        numLabeled(ParamsManager.TIMIT_CMS_WHITE_C7_LIHI,:) = ...
                                          [0      0    11147    0  55456  111133 221254 331793  553041];
        
        numDatasets = size(numLabeled,1);
        for table_i=1:numDatasets
            % KeyType is uint32.
            numLabeledToPrecentMap = containers.Map(0.1, 1); 
            remove(numLabeledToPrecentMap,0.1);

            precent_i = 1;
            numLabeledToPrecentMap(0.01)  = numLabeled(table_i, precent_i);
            precent_i = precent_i + 1;
            numLabeledToPrecentMap(0.1)   = numLabeled(table_i, precent_i);
            precent_i = precent_i + 1;
            numLabeledToPrecentMap(1)     = numLabeled(table_i, precent_i);
            precent_i = precent_i + 1;
            numLabeledToPrecentMap(2.5)     = numLabeled(table_i, precent_i);
            precent_i = precent_i + 1;
            numLabeledToPrecentMap(5)     = numLabeled(table_i, precent_i);
            precent_i = precent_i + 1;
            numLabeledToPrecentMap(10)    = numLabeled(table_i, precent_i);
            precent_i = precent_i + 1;
            numLabeledToPrecentMap(20)    = numLabeled(table_i, precent_i);
            precent_i = precent_i + 1;
            numLabeledToPrecentMap(30)    = numLabeled(table_i, precent_i);
            precent_i = precent_i + 1;
            numLabeledToPrecentMap(50)    = numLabeled(table_i, precent_i);
            precent_i = precent_i + 1;
            
            allTables{table_i} = numLabeledToPrecentMap; %#ok<AGROW>
        end
        
        R = allTables{datasetID};
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

