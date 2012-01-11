classdef MultipleRuns < handle
    %MULTIPLERUNS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=public)
        numExperiments;
    end
    
    properties (Access=private)
        m_runs;
        m_sorted;
    end
    
    methods
        function this = MultipleRuns() % Constructor
            this.m_runs= [];
            this.m_sorted.by_confidence = [];
        end
        
        function addRun(this, singleRun )
            this.m_runs = [this.m_runs; singleRun];
        end
        
        function r = getRun( this, run_i )
            r = this.m_runs(run_i);
        end
    
        function r = sorted_by_confidence( this )
            if isempty(this.m_sorted.by_confidence)
                this.calsSortedByConfidence();
            end
            r = this.m_sorted.by_confidence;
        end
        
        function r = num_runs(this)
            r = this.numExperiments;
        end
    end
        
    methods (Access = private)        
        function calsSortedByConfidence(this)
            
            first_run = 1;
            numUnlabeled = this.getRun(first_run).numUnlabeledVertices();
            
            sorted.by_confidence.accumulative = zeros(numUnlabeled, 1);
            sorted.by_confidence.confidence   = zeros(numUnlabeled, 1);
            sorted.by_confidence.margin       = zeros(numUnlabeled, 1);

            for run_i=1:this.numExperiments
                singleRun = this.getRun(run_i);
                
                run_sorted_by_confidence = ...
                    singleRun.sorted_by_confidence(singleRun.CSSLMC);
                
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
            sorted.by_confidence.accumulative / this.numExperiments;
            sorted.by_confidence.confidence = ...
            sorted.by_confidence.confidence / this.numExperiments;
            sorted.by_confidence.margin = ...
            sorted.by_confidence.margin / this.numExperiments;

            this.m_sorted.by_confidence = sorted.by_confidence;
        end
    end
    
end

