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
        if this.num_runs() > 0
            R = this.getRun(1).availableResultsAlgorithmRange();
        else
            R = [];
        end
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
    
    %% calcAverage_macroMRR
    
    function [m stddev] = calcAverage_macroMRR(this, algorithmType)
        macroMRR = zeros( this.num_runs(), 1);
        for run_i=1:this.num_runs()
             singleRun = this.getRun(run_i);
             macroMRR(run_i) = singleRun.calc_macroMRR_testSet(algorithmType);
        end
        m        = mean(macroMRR);
        stddev   = sqrt(var(macroMRR));
    end

    %% calcAveragePrecisionAndRecall

    function [exactResult estimatedResult] = ...
            calcAveragePrecisionAndRecall(this, algorithmType)
        numLabels = this.getRun(1).numLabels();
        exactPRBEP     = zeros(this.num_runs(), numLabels);
        estimatedPRBEP = zeros(this.num_runs(), numLabels);
        for run_i=1:this.num_runs()

            Logger.log(['MultipleRuns::calcAveragePrecisionAndRecall. run_i =  ' num2str(run_i)]);
            singleRun = this.getRun(run_i);

            for labelIndex = 1:numLabels
                [exact, ~, ~]   = singleRun.calcPRBEP_testSet(algorithmType, labelIndex);
                estimated       = singleRun.estimatePRBEP_testSet(algorithmType, labelIndex);
                Logger.log(['prbep (estimated) for class ' num2str(labelIndex) ...
                    ' = ' num2str(exact) ' (' num2str(estimated) ')']);
                exactPRBEP    (run_i, labelIndex) = exact;
                estimatedPRBEP(run_i, labelIndex) = estimated;
            end
        end
        
        exactResult.mean       = mean(exactPRBEP, 1).';
        exactResult.meanPerRun = mean(exactPRBEP, 2);
        Logger.log('Mean Per Run');
        Logger.log(num2str(exactResult.meanPerRun.'));
        % var(X,w,dim) takes the variance along the dimension dim of X. 
        % Pass in 0 for w to use the default normalization by N – 1, or 1 to use N
        exactResult.stddev     = sqrt(var(exactPRBEP,0,1)).'; 
        estimatedResult.mean   = mean(estimatedPRBEP, 1).';
        estimatedResult.stddev = sqrt(var(estimatedPRBEP,0,1)).'; 
    end
    
    %% calcAverageAccuracy_testSet
    
    function [meanAccuracy stddevAccuracy] ...
            = calcAverageAccuracy_testSet(this, algorithmType)
        accuracyPerRun = zeros(this.num_runs(), 1);
        for run_i=1:this.num_runs()
            singleRun = this.getRun(run_i);
            accuracyPerRun(run_i) = singleRun.accuracy_testSet(algorithmType);
            Logger.log(['run ' num2str(run_i) ' accuracy = ' num2str(accuracyPerRun(run_i))]);
        end
        meanAccuracy    = mean(accuracyPerRun);
        stddevAccuracy  = sqrt(var(accuracyPerRun));
    end
    
    %% calcAverage_macroAccuracy_testSet
    
    function [m stddev] ...
            = calcAverage_macroAccuracy_testSet(this, algorithmType)
        scorePerRun = zeros(this.num_runs(), 1);
        for run_i=1:this.num_runs()
            singleRun = this.getRun(run_i);
            scorePerRun (run_i) = singleRun.macroAccuracy_testSet(algorithmType);
            Logger.log(['run ' num2str(run_i) ' macro accuracy = ' num2str(scorePerRun(run_i))]);
        end
        m       = mean(scorePerRun);
        stddev  = sqrt(var(scorePerRun));
    end
    
    %% calcAverage_levenshtein_testSet
    
    function [m stddev] = calcAverage_levenshtein_testSet...
                                (this, algorithmType)
        scorePerRun = zeros(this.num_runs(), 1);
        for run_i=1:this.num_runs()
            singleRun = this.getRun(run_i);
            scorePerRun (run_i) = singleRun.levenshteinDistance_testSet(algorithmType);
            Logger.log(['run ' num2str(run_i) ' levenshtein = ' num2str(scorePerRun(run_i))]);
        end
        m       = mean(scorePerRun);
        stddev  = sqrt(var(scorePerRun));
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

