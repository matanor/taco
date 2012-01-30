classdef SingleRunFactory < handle
    
properties (GetAccess = private, SetAccess = public)
    m_Weights;
    m_labeledVertices;         
    m_correctLabels;
end
    
methods (Access = public)
    function singleRun = run(this, algorithmParams, algorithmsToRun)

        %% Prepare algorithm parameters

        numIterations     = algorithmParams.numIterations;
        labeledConfidence = algorithmParams.labeledConfidence;
        alpha             = algorithmParams.alpha;
        beta              = algorithmParams.beta;
        classToLabelMap   = algorithmParams.classToLabelMap;
        useGraphHeuristics= algorithmParams.useGraphHeuristics;
        
        %% get graph
        w_nn = this.m_Weights;
        
        %% display parameters
        paramsString = ...
            [ 'labeledConfidence = '    num2str(labeledConfidence) ...
             ' alpha = '                num2str(alpha) ...
             ' beta = '                 num2str(beta) ...
             ' makeSymetric = '         num2str(algorithmParams.makeSymetric)...
             ' numIterations = '        num2str(numIterations) ...
             ' useGraphHeuristics = '   num2str(useGraphHeuristics) ];

         disp(paramsString);
        
        %% create singleRun results object
        singleRun = SingleRun;
        singleRun.m_labeled         = this.m_labeledVertices;
        singleRun.correctLabels     = this.m_correctLabels;
        singleRun.classToLabelMap   = classToLabelMap;
        singleRun.set_graph( w_nn );
        singleRun.set_algorithmParams( algorithmParams );

         %% Run algorithm - label propagation

%         labelPropagation = LP;
%         lpResultsSource = labelPropagation.run...
%             ( w_nn, labeledPositive, labeledNegative );
%         lp_results = LP_Results;
%         lp_results.set_results( lpResultsSource );

        %% prepare params for cssl algorithms

        params.w_nn                 = w_nn;
        params.numIterations        = numIterations;
        params.alpha                = alpha;
        params.beta                 = beta;
        params.labeledConfidence    = labeledConfidence;
        params.classToLabelMap      = classToLabelMap;
        params.useGraphHeuristics   = useGraphHeuristics;

        %% Run algorithm - confidence SSL
        
        if ( algorithmsToRun(SingleRun.CSSLMC) ~= 0)
            algorithm = CSSLMC;
            csslmc_result = CSSLMC_Result;
            this.runCSSL( algorithm, csslmc_result, params );
            singleRun.set_results( csslmc_result, singleRun.CSSLMC );
        end

        %% Run algorithm - confidence SSL MC Full

        if ( algorithmsToRun(SingleRun.CSSLMCF) ~= 0)
            algorithm = CSSLMCF;
            csslmcf_result = CSSLMCF_Result;
            this.runCSSL( algorithm, csslmcf_result, params );
            singleRun.set_results( csslmcf_result,singleRun.CSSLMCF );
        end

        %%

        %result = cssl.runBinary...
        %    ( labeledPositive, labeledNegative, ...
        %      positiveInitialValue,negativeInitialValue);

        %% Run algorithm - MAD

        if ( algorithmsToRun(SingleRun.MAD) ~= 0)
            mad = MAD;

            params.mu1 = 1;
            params.mu2 = 1;
            params.mu3 = 1;
            params.maxIterations = numIterations; %This is an upper bound on the number of iterations
            params.useGraphHeuristics = useGraphHeuristics;

            Ylabeled = this.createInitialLabeledY();

            labeledVertices = this.m_labeledVertices;
            madResultsSource = mad.run( w_nn, Ylabeled, params, labeledVertices );

            mad_results = MAD_Results;
            mad_results.set_results( madResultsSource );
            singleRun.set_results( mad_results  , singleRun.MAD );
        end
                
    end

    function runCSSL( this, algorithm, algorithm_results, params )
        algorithm.m_W                   = params.w_nn;
        algorithm.m_num_iterations      = params.numIterations;
        algorithm.m_alpha               = params.alpha;
        algorithm.m_beta                = params.beta;
        algorithm.m_labeledConfidence   = params.labeledConfidence;
        algorithm.m_useGraphHeuristics  = params.useGraphHeuristics;

        Ylabeled = this.createInitialLabeledY();
        
        algorithmResultsSource = algorithm.run( Ylabeled );

        algorithm_results.set_results(algorithmResultsSource);
    end

    function R = createInitialLabeledY(this)
        %%
        numVertices= size( this.m_Weights, 1);
        numLabels = length( unique( this.m_correctLabels ) );
        labeledVertices_indices         = this.m_labeledVertices;
        labeledVertices_correctLabels   = this.m_correctLabels(labeledVertices_indices);
        R = zeros( numVertices, numLabels);
        for label_i=1:numLabels
            labeledVerticesForClass = ...
                labeledVertices_indices(labeledVertices_correctLabels == label_i);
            R( labeledVerticesForClass, label_i ) = 1;
        end
    end
    
end % methods (Access = public )

end % classdef
