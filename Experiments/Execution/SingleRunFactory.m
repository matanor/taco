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
        
        job = JobManager.createJob(fileFullPath, 'asyncSingleRun', outputManager);
    end
    
    %% run
    
    function singleRun = run(this, algorithmParams, algorithmsToRun)
        %% create singleRun results object
        singleRun = SingleRun(this.m_graph.correctLabels(), ...
                              this.m_constructionParams, ...
                              this.m_trunsductionSet);
        
        for algorithm_i=algorithmsToRun.algorithmsRange()
            this.runAlgorithm( singleRun, algorithm_i, algorithmParams{algorithm_i} );
        end
                
    end
    
    %% get_wnnGraph
    
    function R = get_wnnGraph(this, makeSymetric, K)
        disp(['get_wnnGraph. K = ' num2str(K) ...
              ' makeSymetric = ' num2str(makeSymetric)]);
        this.m_graph.createKnn ( K );
        if ( makeSymetric ~= 0)
            R = this.m_graph.get_symetricNN();
        else
            R = this.m_graph.get_NN();
        end
    end

    %% runAlgorithm
    
    function runAlgorithm( this, singleRun, algorithmType, params )
        
        [algorithm algorithm_results ] = this.createAlgorithm( algorithmType );
        
        algorithm.m_W = this.get_wnnGraph( params.makeSymetric, params.K );
        algorithm.m_num_iterations  = params.maxIterations;
        algorithm.m_priorY          = this.createInitialLabeledY(params.labeledInitMode);
        algorithm.m_labeledSet      = this.m_trunsductionSet.labeled();
        
        this.loadSpecificAlgorithmParams( algorithm, algorithmType, params );
        
        algorithmResultsSource = algorithm.run();

        algorithm_results.set_results(algorithmResultsSource, ...
                                      ParamsManager.SAVE_ALL_ITERATIONS_IN_RESULT);
        algorithm_results.set_params( params );
        
        singleRun.set_results( algorithm_results, algorithmType );
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
                % set -1 for labeled vertex not belonging to other classes.
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

methods (Static)
    
    %% loadSpecificAlgorithmParams
    
    function loadSpecificAlgorithmParams( algorithm, algorithmType, params )
        switch algorithmType
            case SingleRun.CSSLMC
                algorithm.m_alpha               = params.alpha;
                algorithm.m_beta                = params.beta;
                algorithm.m_labeledConfidence   = params.labeledConfidence;
                algorithm.m_useGraphHeuristics  = params.useGraphHeuristics;
            case SingleRun.CSSLMCF
                algorithm.m_alpha               = params.alpha;
                algorithm.m_beta                = params.beta;
                algorithm.m_labeledConfidence   = params.labeledConfidence;
                algorithm.m_useGraphHeuristics  = params.useGraphHeuristics;
            case SingleRun.MAD
                algorithm.m_mu1                 = params.mu1;
                algorithm.m_mu2                 = params.mu2;
                algorithm.m_mu3                 = params.mu3;
                algorithm.m_useGraphHeuristics  = params.useGraphHeuristics;
            case SingleRun.AM
                algorithm.m_v      = params.am_v;
                algorithm.m_mu     = params.am_mu;
                algorithm.m_alpha  = params.am_alpha;
            otherwise
                disp(['loadSpecificAlgorithmParams::Error. unknown algorithm type ' ...
                        num2str( algorithmType) ]);
        end                
    end
    
    %% createAlgorithm
    
    function [algorithm algorithm_result] = createAlgorithm( algorithmType )
        switch algorithmType
            case SingleRun.CSSLMC
                algorithm = CSSLMC;
                algorithm_result = CSSLMC_Result;
            case SingleRun.CSSLMCF
                algorithm = CSSLMCF;
                algorithm_result = CSSLMCF_Result;
            case SingleRun.MAD
                algorithm = MAD;
                algorithm_result = MAD_Results;
            case SingleRun.AM
                algorithm = AM;
                algorithm_result = AM_Result;
            otherwise
                disp(['createAlgorithm::Error. unknown algorithm type ' ...
                        num2str( algorithmType) ]);
        end
    end
end % methods (Static)

end % classdef
