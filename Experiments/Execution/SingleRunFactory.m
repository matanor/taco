classdef SingleRunFactory < handle
    
properties (Access = public)
    m_constructionParams;
    m_graph;
    m_trunsductionSet;
    m_clearAlgorithmOutput;
end
    
methods (Access = public)
    %% constructor 
    
    function this = SingleRunFactory( constructionParams, graph, trunsductionSet )
        this.m_constructionParams   = constructionParams;
        this.m_graph                = graph;
        this.m_trunsductionSet      = trunsductionSet;
        this.m_clearAlgorithmOutput = ParamsManager.CLEAR_ALGORITHM_OUTPUT;
    end
    
    %% set_graph
    
    function set_graph( this, value )
        this.m_graph = value;
    end
    
    %% scheduleAsyncRun
    
    function job = scheduleAsyncRun(this, algorithmParams, algorithmsToRun, ...
                              fileFullPath, outputManager )
        Logger.log('scheduleAsyncRun');
        % save us to a file.
        this.m_graph.clearWeights(); % This will be reconstructed when loading task from disk
        graphFileFullPath = this.m_graph.fileFullPath(); %#ok<NASGU>
        save(fileFullPath,'this','algorithmParams','algorithmsToRun','graphFileFullPath');
        
        job = JobManager.createJob(fileFullPath, 'asyncSingleRun', outputManager);
    end
    
    %% run
    
    function singleRun = run(this, algorithmParams, algorithmsToRun, jobFileFullPath)
        %% create singleRun results object
        singleRun = SingleRun(this.m_graph.correctLabels(), ...
                              this.m_constructionParams, ...
                              this.m_trunsductionSet);
        singleRun.set_structuredSegments(this.m_graph.structuredSegments());
        singleRun.set_fileFullPath(jobFileFullPath);
        
        for algorithm_i=algorithmsToRun.algorithmsRange()
            this.runAlgorithm( singleRun, algorithm_i, algorithmParams{algorithm_i} );
        end
        
        singleRun.createCachedResults();
        
        if (this.m_clearAlgorithmOutput)
            singleRun.clearAlgorithmOutput();
        end     
    end
    
    %% get_wnnGraph
    
    function R = get_wnnGraph(this, makeSymetric, K)
        Logger.log(['get_wnnGraph. K = ' num2str(K) ...
              ' makeSymetric = ' num2str(makeSymetric)]);
        this.m_graph.createKnn ( K );
        if ( makeSymetric ~= 0)
            R = this.m_graph.get_symetricNN();
        else
            R = this.m_graph.get_NN();
        end
        degreePerVertex = sum(R ~=0,2);
        degree.mean = mean(degreePerVertex);
        degree.max = max(degreePerVertex);
        degree.min = min(degreePerVertex);
        Logger.log(['Graph Properties:'...
                    ' avg degree = ' num2str(degree.mean) ...
                    ' min degree = ' num2str(degree.min) ...
                    ' max degree = ' num2str(degree.max) ]);
    end

    %% runAlgorithm
    
    function runAlgorithm( this, singleRun, algorithmType, params )
        
        [algorithm algorithm_results ] = this.createAlgorithm( algorithmType );

        if params.isCalculateKNN
            algorithm.m_W = this.get_wnnGraph( params.makeSymetric, params.K );
        else
            algorithm.m_W = this.m_graph.get_weights();
        end
        algorithm.m_num_iterations  = params.maxIterations;
        algorithm.setLabeledSet(this.m_trunsductionSet.labeled());
        
        algorithm.createInitialLabeledY(this.m_graph, params.labeledInitMode);
        
        if algorithmType == SingleRun.CSSLMC
            algorithm.setTransitionMatrix( this.m_graph.transitionMatrix() );
            algorithm.setStructuredEdges( this.m_graph.structuredEdges() );
        end
        
        this.loadSpecificAlgorithmParams( algorithm, algorithmType, params );
        
        algorithmResultsSource = algorithm.run();

        algorithm_results.set_results(algorithmResultsSource, ...
                                      ParamsManager.SAVE_ALL_ITERATIONS_IN_RESULT);
        algorithm_results.set_params( params );
        
        singleRun.set_results( algorithm_results, algorithmType );
    end
    
end % methods (Access = public )

methods (Static)
    
    %% loadSpecificAlgorithmParams
    
    function loadSpecificAlgorithmParams( algorithm, algorithmType, params )
        switch algorithmType
            case SingleRun.CSSLMC
                algorithm.m_alpha                   = params.alpha;
                algorithm.m_beta                    = params.beta;
                algorithm.m_zeta                    = params.zeta;
                algorithm.m_labeledConfidence       = params.labeledConfidence;
                algorithm.m_useGraphHeuristics      = params.useGraphHeuristics;
                algorithm.m_isUsingL2Regularization = params.isUsingL2Regularization;
                algorithm.m_isUsingSecondOrder      = params.isUsingSecondOrder;
                algorithm.m_structuredTermType      = params.structuredTermType;
                algorithm.m_objectiveType           = params.m_csslObjectiveType;
                algorithm.m_descendMode             = params.descendMethodCSSL;
            case SingleRun.CSSLMCF
                algorithm.m_alpha                   = params.alpha;
                algorithm.m_beta                    = params.beta;
                algorithm.m_zeta                    = params.zeta;
                algorithm.m_labeledConfidence       = params.labeledConfidence;
                algorithm.m_useGraphHeuristics      = params.useGraphHeuristics;
                algorithm.m_isUsingL2Regularization = params.isUsingL2Regularization;
                algorithm.m_isUsingSecondOrder      = params.isUsingSecondOrder;
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
                Logger.log(['loadSpecificAlgorithmParams::Error. unknown algorithm type ' ...
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
                Logger.log(['createAlgorithm::Error. unknown algorithm type ' ...
                        num2str( algorithmType) ]);
        end
    end
end % methods (Static)

end % classdef
