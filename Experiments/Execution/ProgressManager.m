classdef ProgressManager < handle
    %PROGRESSMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
properties (Access = public)
    m_currentExperiment;
    m_numExperiments;
    m_currentParameterRun;
    m_numParameterRuns;
    m_currentOptimizationMethod;
    m_currentEvaluationRun;
    m_numEvaluationRuns;
    m_currentOptimizationRun;
    m_numOptimizationRuns;
end
    
methods
    
    %% Constructor
    
    function this = ProgressManager(numExperiments, numParameterRuns)
        this.m_numExperiments   = numExperiments;
        this.m_numParameterRuns = numParameterRuns;
    end
    
    %% set_currentExperiment
    
    function set_currentExperiment(this, value)
        this.m_currentExperiment = value;
    end
    
    %% currentExperimentRun
    
    function R = currentExperimentRun(this)
        R = this.m_currentExperiment;
    end
    
    %% set_currentParameterRun
    
    function set_currentParameterRun(this, value)
        this.m_currentParameterRun = value;
    end
    
    %% currentParameterRun
    
    function R = currentParameterRun(this)
        R = this.m_currentParameterRun;
    end
    
    %% set_currentEvaluationRun
    
    function set_currentEvaluationRun(this, value)
        this.m_currentEvaluationRun = value;
    end
    
    %% currentEvaluationRun
    
    function R = currentEvaluationRun(this)
        R = this.m_currentEvaluationRun;
    end

    %% set_numEvaluationRuns
    
    function set_numEvaluationRuns(this, value)
        this.m_numEvaluationRuns = value;
    end
    
    %% set_currentOptimizationMethod
    
    function set_currentOptimizationMethod(this, value)
        this.m_currentOptimizationMethod= value;
    end
    
    %% set_currentOptimizationRun
    
    function set_currentOptimizationRun(this, value)
        this.m_currentOptimizationRun = value;
    end
    
    %% currentOptimizationRun
    
    function R = currentOptimizationRun(this)
        R = this.m_currentOptimizationRun;
    end

    %% set_numOptimizationRuns
    
    function set_numOptimizationRuns(this, value)
        this.m_numOptimizationRuns = value;
    end

    %% displayEvaluationProgress
    
    function displayEvaluationProgress(this)
        optimizationMethodName = ...
            OptimizationMethodToStringConverter.convert(this.m_currentOptimizationMethod);
        progressString = ...
        [ 'on experiment '   num2str(this.m_currentExperiment)     ...
         ' out of '          num2str(this.m_numExperiments)        ...
         '. parameter run  ' num2str(this.m_currentParameterRun)   ...
         ' out of '          num2str(this.m_numParameterRuns)      ...
         '. ' optimizationMethodName ...
         '. evaluation run ' num2str(this.m_currentEvaluationRun)  ...
         ' out of '          num2str(this.m_numEvaluationRuns) ];

        disp(progressString);
    end
    
    %% displayOptimizationProgress
    
    function displayOptimizationProgress(this)
        progressString = ...
        [ 'on experiment '      num2str(this.m_currentExperiment)     ...
         ' out of '             num2str(this.m_numExperiments)        ...
         '. parameter run '     num2str(this.m_currentParameterRun)   ...
         ' out of '             num2str(this.m_numParameterRuns)      ...
         '. optimization run '  num2str(this.m_currentOptimizationRun)...
         ' out of '             num2str(this.m_numOptimizationRuns) ];

        disp(progressString);
    end
    
    %% displayExperimentAndParameterRun
    
    function displayExperimentAndParameterRun(this)
        progressString = ...
        [ 'on experiment '      num2str(this.m_currentExperiment)     ...
         ' out of '             num2str(this.m_numExperiments)        ...
         '. parameter run '     num2str(this.m_currentParameterRun)   ...
         ' out of '             num2str(this.m_numParameterRuns) ];

        disp(progressString);
    end

end
    
end

