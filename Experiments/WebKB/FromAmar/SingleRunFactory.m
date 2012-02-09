classdef SingleRunFactory < handle
    
properties (Access = public)
    m_constructionParams;
    m_graph;
end
    
methods (Access = public)   
    %% scheduleAsyncRun
    
    function job = scheduleAsyncRun(this, algorithmParams, algorithmsToRun, ...
                              fileFullPath, outputManager )
        disp('scheduleAsyncRun');
        % save us to a file.
        this.m_graph.w_nn = []; % This will be reconstructed
        this.m_graph.w_nn_symetric  = []; % This will be reconstructed
        this.m_graph.weights = []; % This will be reconstructed
        save(fileFullPath,'this','algorithmParams','algorithmsToRun');
        
        job = JobManager.scheduleJob(fileFullPath, 'asyncSingleRun', outputManager);
    end
    
    function singleRun = run(this, algorithmParams, algorithmsToRun)
        %% get graph
%         if ( algorithmParams{SingleRun.CSSLMC}.makeSymetric ~= 0)
%             w_nn = this.m_graph.w_nn_symetric;
%         else
%             w_nn = this.m_graph.w_nn;
%         end
        
        %% display parameters
%         paramsString = [' makeSymetric = ' num2str(algorithmParams{SingleRun.CSSLMC}.makeSymetric) ];
%         disp(paramsString);
        
        %% create singleRun results object
        singleRun = SingleRun;
        singleRun.m_labeled         = this.m_graph.labeledVertices;
        singleRun.correctLabels     = this.m_graph.labels;
%         singleRun.set_graph( w_nn );
        singleRun.set_constructionParams( this.m_constructionParams );
        singleRun.set_folds( this.m_graph.folds );

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
            if (  algorithmParams{SingleRun.MAD}.makeSymetric ~= 0)
                w_nn = this.m_graph.w_nn_symetric;
            else
                w_nn = this.m_graph.w_nn;
            end

            madParams = algorithmParams{SingleRun.MAD};
            Ylabeled = this.createInitialLabeledY(madParams.labeledInitMode);

            labeledVertices = this.m_graph.labeledVertices;
            madResultsSource = mad.run( w_nn, Ylabeled, madParams, labeledVertices );

            mad_results = MAD_Results;
            mad_results.set_results( madResultsSource );
            mad_results.set_params( madParams );
            singleRun.set_results( mad_results  , singleRun.MAD );
        end
                
    end
    
    %% runCSSL

    function runCSSL( this, algorithm, algorithm_results, params )
        if ( params.makeSymetric ~= 0)
            algorithm.m_W = this.m_graph.w_nn_symetric;
        else
            algorithm.m_W = this.m_graph.w_nn;
        end
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
        numVertices= size( this.m_graph.weights, 1);
        numLabels = length( unique( this.m_graph.labels ) );
        labeledVertices_indices         = this.m_graph.labeledVertices;
        labeledVertices_correctLabels   = this.m_graph.labels(labeledVertices_indices);
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
