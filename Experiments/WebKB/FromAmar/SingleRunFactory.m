classdef SingleRunFactory < handle
    
properties (GetAccess = private, SetAccess = public)
    m_Weights;
    m_Ylabeled;
    m_correctLabels;
end
    
methods (Access = public)
    function singleRun = run(this, algorithmParams)

        %% Prepare algorithm parameters

        numIterations     = algorithmParams.numIterations;
        labeledConfidence = algorithmParams.labeledConfidence;
        alpha             = algorithmParams.alpha;
        beta              = algorithmParams.beta;
        classToLabelMap   = algorithmParams.classToLabelMap;
        useGraphHeuristics= algorithmParams.useGraphHeuristics;

        %% display parameters
        paramsString = ...
            [ 'labeledConfidence = ' num2str(labeledConfidence) ...
             ' alpha = '             num2str(alpha) ...
             ' beta = '              num2str(beta) ...
             ' makeSymetric = '      num2str(algorithmParams.makeSymetric)...
             ' numIterations = '     num2str(numIterations)];

         disp(paramsString);

        %%
        w_nn = this.m_Weights;
        
        %% get positive and negative labeled vertices

        labeledPositive = this.m_Ylabeled(:, 1);
        labeledNegative = this.m_Ylabeled(:, 2);

         %% Run algorithm - label propagation

        labelPropagation = LP;
        lpResultsSource = labelPropagation.run...
            ( w_nn, labeledPositive, labeledNegative );
        lp_results = LP_Results;
        lp_results.set_results( lpResultsSource );

        %% prepare params for cssl algorithms

        params.w_nn                 = w_nn;
        params.numIterations        = numIterations;
        params.alpha                = alpha;
        params.beta                 = beta;
        params.labeledConfidence    = labeledConfidence;
        params.labeledPositive      = labeledPositive;
        params.labeledNegative      = labeledNegative;
        params.classToLabelMap      = classToLabelMap;

        %% Run algorithm - confidence SSL
         
        algorithm = CSSLMC;
        csslmc_result = CSSLMC_Result;
        SingleRunFactory.runCSSL( algorithm, csslmc_result, params );

        %% Run algorithm - confidence SSL MC Full

        algorithm = CSSLMCF;
        csslmcf_result = CSSLMCF_Result;
        SingleRunFactory.runCSSL( algorithm, csslmcf_result, params );

        %%

        %result = cssl.runBinary...
        %    ( labeledPositive, labeledNegative, ...
        %      positiveInitialValue,negativeInitialValue);

        %% Run algorithm - MAD

        mad = MAD;

        params.mu1 = 1;
        params.mu2 = 1;
        params.mu3 = 1;
        params.maxIterations = numIterations; %This is an upper bound on the number of iterations
        params.useGraphHeuristics = useGraphHeuristics;
        
        numVertices = size(params.w_nn,1);
        numLabels   = size(params.classToLabelMap,1);
        Ylabeled = SingleRunFactory.createLabeledY...
            (  numVertices, numLabels, ...
               params.labeledNegative, ...
               params.labeledPositive) ;

        labeledVertices = this.m_Ylabeled(:);
        madResultsSource = mad.run( w_nn, Ylabeled, params, labeledVertices );

        mad_results = MAD_Results;
        mad_results.set_results( madResultsSource );

        %% Create a single run object for results.

        singleRun = SingleRun;
        singleRun.labeledPositive = labeledPositive;
        singleRun.labeledNegative = labeledNegative;
        singleRun.correctLabels = this.m_correctLabels;
        singleRun.classToLabelMap = classToLabelMap;
        singleRun.set_graph( w_nn );
        singleRun.set_algorithmParams( algorithmParams );
        singleRun.set_results( csslmc_result, singleRun.CSSLMC );
        singleRun.set_results( csslmcf_result, singleRun.CSSLMCF );
        singleRun.set_results( lp_results   , singleRun.LP )
        singleRun.set_results( mad_results  , singleRun.MAD );
    end
    
end % methods (Access = public )
    
methods (Static)
    function runCSSL( algorithm, algorithm_results, params )
        algorithm.m_W                 = params.w_nn;
        algorithm.m_num_iterations    = params.numIterations;
        algorithm.m_alpha             = params.alpha;
        algorithm.m_beta              = params.beta;
        algorithm.m_labeledConfidence = params.labeledConfidence;

        numVertices = size(params.w_nn,1);
        numLabels   = size(params.classToLabelMap,1);
        
        Ylabeled = SingleRunFactory.createLabeledY...
            (  numVertices, numLabels, ...
               params.labeledNegative, ...
               params.labeledPositive) ;

        algorithmResultsSource = algorithm.run( Ylabeled );

        algorithm_results.set_results(algorithmResultsSource);
    end
    
    function R = createLabeledY(numVertices, numLabels, ...
                                labeledNegative, labeledPositive )
        R = zeros( numVertices, numLabels);
        NEGATIVE = 1; POSITIVE = 2;
        R( labeledNegative, NEGATIVE ) = 1;
        R( labeledPositive, POSITIVE ) = 1;
    end
    
end % methods (Static)
end % classdef
