classdef ConstructionParams < handle
    %CONSTRUCTIONPARAMS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        K;
        numLabeled;
        fileName;
        classToLabelMap;
        numFolds;
        numInstancesPerClass;
    end % (Access = public)
    
    methods (Static)
        %% display
        function display(this)
        
            s = [' K = '                        num2str(this.K) ...
                 ' numLabeled = '               num2str(this.numLabeled) ...
                 ' numFolds = '                 num2str(this.numFolds)];

            disp(s );
        end
        
        function R = numLabeledPerClass(this)
            R = this.numLabeled / this.numFolds;
        end
    end
    
end

