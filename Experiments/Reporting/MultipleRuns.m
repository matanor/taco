classdef MultipleRuns < handle
    %MULTIPLERUNS Summary of this class goes here
    %   Detailed explanation goes here

properties (Access=private)
    m_runs;
    m_sorted;
end
    
methods
    function this = MultipleRuns() % Constructor
        this.m_runs= [];
        this.m_sorted.by_confidence = [];
    end
    
    %% availableResultsAlgorithmRange
        
    function R = availableResultsAlgorithmRange(this)
        R = this.getRun(1).availableResultsAlgorithmRange();
    end

    %% constructionParams
    
    function R = constructionParams(this)
        R = this.getRun(1).constructionParams;
    end

    %% algorithmParams
    
    function R = algorithmParams(this)
        R = this.getRun(1).algorithmParams;
    end

    %% addRun
    
    function addRun(this, singleRun )
        this.m_runs = [this.m_runs; singleRun];
    end

    %% getRun
    
    function r = getRun( this, run_i )
        r = this.m_runs(run_i);
    end

    %% sorted_by_confidence
    
    function r = sorted_by_confidence( this, algorithmType )
        r = this.calsSortedByConfidence(algorithmType);
    end
    
    %% num_runs

    function r = num_runs(this)
        r = length(this.m_runs);
    end
    
    %% isResultsAvailable

    function r = isResultsAvailable( this, algorithmType )
        r = this.getRun(1).isResultsAvailable(algorithmType);
    end
    
    %% calcAverageMRR
    
    function [meanMRR stddevMRR] = calcAverageMRR(this, algorithmType)
        MRR = zeros( this.num_runs(), 1);
        for run_i=1:this.num_runs()
             singleRun = this.getRun(run_i);
             MRR(run_i) = singleRun.calcMRR_testSet(algorithmType);
        end
        meanMRR     = mean(MRR);
        stddevMRR   = sqrt(var(MRR));
    end

    %% calcAveragePrecisionAndRecall

    function [prbepAverage estimatedPrebpAverage] = ...
            calcAveragePrecisionAndRecall(this, algorithmType)
        numLabels = this.getRun(1).numLabels();
        prbepAverage            = zeros(numLabels, 1);
        estimatedPrebpAverage   = zeros(numLabels, 1);
        for run_i=1:this.num_runs()

            disp(['MultipleRuns::calcAveragePrecisionAndRecall. run_i =  ' num2str(run_i)]);
            singleRun = this.getRun(run_i);

            for labelIndex = 1:numLabels
                [prbep, ~, ~]   = singleRun.calcPRBEP_testSet(algorithmType, labelIndex);
                estimated_prbep  = singleRun.estimatePRBEP_testSet(algorithmType, labelIndex);
                disp(['prbep (estimated) for class ' num2str(labelIndex) ' = ' num2str(prbep)...
                  ' (' num2str(estimated_prbep) ')']);
                prbepAverage(labelIndex) = prbepAverage(labelIndex) + prbep;
                estimatedPrebpAverage(labelIndex) = estimatedPrebpAverage(labelIndex) + estimated_prbep;
            end
        end
        prbepAverage          = prbepAverage / this.num_runs();
        estimatedPrebpAverage = estimatedPrebpAverage / this.num_runs();
    end
    
    %% calcAverageAccuracy_testSet
    
    function R = calcAverageAccuracy_testSet(this, algorithmType)
        averageAccuracy = 0;
        for run_i=1:this.num_runs()
            singleRun = this.getRun(run_i);
            singleRunAccuracy = singleRun.accuracy_testSet(algorithmType);
            disp(['run ' num2str(run_i) ' accuracy = ' num2str(singleRunAccuracy)]);
            averageAccuracy = averageAccuracy + singleRunAccuracy;
        end
        averageAccuracy = averageAccuracy / this.num_runs();
        R = averageAccuracy;
    end
    
end
        
methods (Access = private)        

    %% checkConstructionParams
    
    function checkConstructionParams(this, constructionParams)
        cp = this.constructionParams;
        assert( cp.K                    == constructionParams.K);
        assert( cp.numLabeled           == constructionParams.numLabeled);
        assert( cp.numInstancesPerClass == constructionParams.numInstancesPerClass);
    end

     %% checkAlgorithmParams
     
    function checkAlgorithmParams   (this, algorithmParams)
        ap = this.algorithmParams;
        assert( ap.alpha             == algorithmParams.alpha);
        assert( ap.beta              == algorithmParams.beta);
        assert( ap.labeledConfidence == algorithmParams.labeledConfidence);
        assert( ap.makeSymetric      == algorithmParams.makeSymetric);
    end

    %% calsSortedByConfidence
    
    function r = calsSortedByConfidence(this, algorithmType)

        first_run = 1;
        numUnlabeled = this.getRun(first_run).numUnlabeledVertices();

        sorted.by_confidence.accumulative = zeros(numUnlabeled, 1);
        sorted.by_confidence.confidence   = zeros(numUnlabeled, 1);
        sorted.by_confidence.margin       = zeros(numUnlabeled, 1);

        for run_i=1:this.num_runs()
            singleRun = this.getRun(run_i);

            run_sorted_by_confidence = ...
                singleRun.sorted_by_confidence(algorithmType);

            sorted.by_confidence.accumulative = ...
            sorted.by_confidence.accumulative + ...
                run_sorted_by_confidence.accumulative;

            sorted.by_confidence.confidence = ...
            sorted.by_confidence.confidence + ...
                run_sorted_by_confidence.confidence;

            sorted.by_confidence.margin = ...
            sorted.by_confidence.margin + ...
                run_sorted_by_confidence.margin;
        end

        sorted.by_confidence.accumulative = ...
        sorted.by_confidence.accumulative / this.num_runs();
        sorted.by_confidence.confidence = ...
        sorted.by_confidence.confidence / this.num_runs();
        sorted.by_confidence.margin = ...
        sorted.by_confidence.margin / this.num_runs();

        r = sorted.by_confidence;
    end
end % methods (Access = private)
    
end % classdef

