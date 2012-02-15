classdef TrunsductionSet < handle
    %TRUNSDUCTIONSET Summary of this class goes here
    %   Detailed explanation goes here
    
properties
    m_training;
    m_testing;
    m_labeled;
    m_numFolds;
end
    
methods
    %% Constructor
    
    function this = TrunsductionSet( folds )
        this.m_training = folds(1,:);
        this.m_testing = folds(2:end, :);
        this.m_testing = this.m_testing(:); % make the test folds a clumn vector,
        this.m_numFolds = size(folds, 1);
    end
    
    %% selectLabeled
    
    function selectLabeled( this, graph, balancedLabeled, ...
                            classToLabelMap, numLabeled)
        labeledSelector = LabeledSelector( graph );   
        this.m_labeled = labeledSelector.select...
            ( balancedLabeled, this.trainingSet(), classToLabelMap, ...
              numLabeled, ...
              this.m_numFolds );
    end
    
    %% trainingSet
    
    function R = trainingSet(this)
        R = this.m_training;
    end
    
    %% testSet
    
    function R = testSet(this)
        R = this.m_testing;
    end
    
    %% labeled
    
    function R = labeled(this)
        R = this.m_labeled;
    end
    
end
    
end

