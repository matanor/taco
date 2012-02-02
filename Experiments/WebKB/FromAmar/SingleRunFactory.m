classdef SingleRunFactory < handle
    
properties (GetAccess = private, SetAccess = public)
    m_Weights;
    m_labeledVertices;         
    m_correctLabels;
    m_constructionParams;
    m_folds;
end
    
methods (Access = public)
    function singleRun = run(this, algorithmParams, algorithmsToRun)
        %% Prepare algorithm parameters

        numIterations     = algorithmParams.numIterations;
        labeledConfidence = algorithmParams.labeledConfidence;
        alpha             = algorithmParams.alpha;
        beta              = algorithmParams.beta;
        useGraphHeuristics= algorithmParams.useGraphHeuristics;
        
        %% get graph
        w_nn = this.m_Weights;
        
        %% display parameters
        paramsString = [' makeSymetric = ' num2str(algorithmParams.makeSymetric) ];
        disp(paramsString);
        
        %% create singleRun results object
        singleRun = SingleRun;
        singleRun.m_labeled         = this.m_labeledVertices;
        singleRun.correctLabels     = this.m_correctLabels;
        singleRun.set_graph( w_nn );
        singleRun.set_algorithmParams   ( algorithmParams );
        singleRun.set_constructionParams( this.m_constructionParams );
        singleRun.set_folds( this.m_folds );

        %% prepare params for cssl algorithms

        params.w_nn                 = w_nn;
        params.numIterations        = numIterations;
        params.alpha                = alpha;
        params.beta                 = beta;
        params.labeledConfidence    = labeledConfidence;
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

        %% Run algorithm - MAD

        if ( algorithmsToRun(SingleRun.MAD) ~= 0)
            mad = MAD;

            clear params;
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
    
    %% runCSSL

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
    
    %% createInitialLabeledY

    function R = createInitialLabeledY(this)
        numVertices= size( this.m_Weights, 1);
        numLabels = length( unique( this.m_correctLabels ) );
        labeledVertices_indices         = this.m_labeledVertices;
        labeledVertices_correctLabels   = this.m_correctLabels(labeledVertices_indices);
        R = zeros( numVertices, numLabels);
        availableLabels = 1:numLabels;
        
        for label_i=availableLabels
            labeledVerticesForClass = ...
                labeledVertices_indices(labeledVertices_correctLabels == label_i);
            % set +1 for lebeled vertex belonging to a class.
            R( labeledVerticesForClass, label_i ) = 1;
            if (0)
                % set -1 for lebeled vertex not belonging to other classes.
                otherLabels = setdiff(availableLabels, label_i);
                R( labeledVerticesForClass, otherLabels ) = -1;
            end
        end
        if (0)
            % set -1 for unlabeled vertices not belonging to any class.
            unlabeled = setdiff( 1:numVertices, labeledVertices_indices );
            R( unlabeled, : ) = -1;
        end
    end
    
end % methods (Access = public )

end % classdef
