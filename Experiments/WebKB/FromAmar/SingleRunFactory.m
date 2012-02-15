classdef SingleRunFactory < handle
    
properties (Access = public)
    m_constructionParams;
    m_graph;
    m_trunsductionSet;
end
    
methods (Access = public)
    %% constructor 
    
    function this = SingleRunFactory( constructionParams, graph, trunsductionSet )
        this.m_constructionParams   = constructionParams;
        this.m_graph                = graph;
        this.m_trunsductionSet      = trunsductionSet;
    end
    
    %% set_graph
    
    function set_graph( this, value )
        this.m_graph = value;
    end
    
    %% scheduleAsyncRun
    
    function job = scheduleAsyncRun(this, algorithmParams, algorithmsToRun, ...
                              fileFullPath, outputManager )
        disp('scheduleAsyncRun');
        % save us to a file.
        this.m_graph.clearWeights(); % This will be reconstructed when loading task from disk
        save(fileFullPath,'this','algorithmParams','algorithmsToRun');
        
        job = JobManager.scheduleJob(fileFullPath, 'asyncSingleRun', outputManager);
    end
    
    %% run
    
    function singleRun = run(this, algorithmParams, algorithmsToRun)
        %% create singleRun results object
        singleRun = SingleRun(this.m_graph.correctLabels(), ...
                              this.m_constructionParams, ...
                              this.m_trunsductionSet);

        %% Run algorithm - confidence SSL
        
        if ( algorithmsToRun.shouldRun(SingleRun.CSSLMC) ~= 0)
            algorithm = CSSLMC;
            csslmc_result = CSSLMC_Result;
            this.runCSSL( algorithm, csslmc_result, algorithmParams{SingleRun.CSSLMC} );
            singleRun.set_results( csslmc_result, singleRun.CSSLMC );
        end

        %% Run algorithm - confidence SSL MC Full

        if ( algorithmsToRun.shouldRun(SingleRun.CSSLMCF) ~= 0)
            algorithm = CSSLMCF;
            csslmcf_result = CSSLMCF_Result;
            this.runCSSL( algorithm, csslmcf_result, algorithmParams{SingleRun.CSSLMCF} );
            singleRun.set_results( csslmcf_result, singleRun.CSSLMCF );
        end

        %% Run algorithm - MAD

        if ( algorithmsToRun.shouldRun(SingleRun.MAD) ~= 0)
            mad = MAD;
            w_nn = this.get_wnnGraph( algorithmParams{SingleRun.MAD}.makeSymetric, ...
                                      algorithmParams{SingleRun.MAD}.K);

            madParams = algorithmParams{SingleRun.MAD};
            Ylabeled = this.createInitialLabeledY(madParams.labeledInitMode);

            labeledVertices = this.m_trunsductionSet.labeled();
            madResultsSource = mad.run( w_nn, Ylabeled, madParams, labeledVertices );

            mad_results = MAD_Results;
            mad_results.set_results( madResultsSource );
            mad_results.set_params( madParams );
            singleRun.set_results( mad_results  , singleRun.MAD );
        end
                
    end
    
    %% get_wnnGraph
    
    function R = get_wnnGraph(this, makeSymetric, K)
        this.m_graph.createKnn ( K );
        if ( makeSymetric ~= 0)
            R = this.m_graph.get_symetricNN();
        else
            R = this.m_graph.get_NN();
        end
    end
    
    %% runCSSL

    function runCSSL( this, algorithm, algorithm_results, params )
        algorithm.m_W = this.get_wnnGraph( params.makeSymetric, params.K );
        algorithm.m_num_iterations      = params.maxIterations;
        algorithm.m_alpha               = params.alpha;
        algorithm.m_beta                = params.beta;
        algorithm.m_labeledConfidence   = params.labeledConfidence;
        algorithm.m_useGraphHeuristics  = params.useGraphHeuristics;
        
        Ylabeled = this.createInitialLabeledY(params.labeledInitMode);
        
        algorithmResultsSource = algorithm.run( Ylabeled );

        algorithm_results.set_results(algorithmResultsSource);
        algorithm_results.set_params( params );
    end
    
    %% createInitialLabeledY

    function R = createInitialLabeledY(this, labeledInitMode)
        numVertices = this.m_graph.numVertices();
        numLabels = length( this.m_graph.availabelLabels() );
        labeledVertices_indices         = this.m_trunsductionSet.labeled();
        labeledVertices_correctLabels   = ...
            this.m_graph.correctLabelsForVertices(labeledVertices_indices);
        R = zeros( numVertices, numLabels);
        availableLabels = 1:numLabels;
        
        for label_i=availableLabels
            labeledVerticesForClass = ...
                labeledVertices_indices(labeledVertices_correctLabels == label_i);
            % set +1 for lebeled vertex belonging to a class.
            R( labeledVerticesForClass, label_i ) = 1;
            if (labeledInitMode == ParamsManager.LABELED_INIT_MINUS_PLUS_ONE ||...
                labeledInitMode == ParamsManager.LABELED_INIT_MINUS_PLUS_ONE_UNLABELED)
                % set -1 for lebeled vertex not belonging to other classes.
                otherLabels = setdiff(availableLabels, label_i);
                R( labeledVerticesForClass, otherLabels ) = -1;
            end
        end
        if (labeledInitMode == ParamsManager.LABELED_INIT_MINUS_PLUS_ONE_UNLABELED)
            % set -1 for unlabeled vertices not belonging to any class.
            unlabeled = setdiff( 1:numVertices, labeledVertices_indices );
            R( unlabeled, : ) = -1;
        end
    end
    
end % methods (Access = public )

end % classdef
