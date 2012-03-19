classdef GraphTrunsductionBase < handle
    %GRAPHTRUNSDUCTIONBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        m_priorY;           % Y - prior labeling, its size should be
                            %       number of vertices X number of labels.
        m_labeledSet;       % indices of labeled vertices.
        m_W;                % The weights of the graph.
        m_num_iterations;
    end
    
methods
    
    %% numVertices
    
    function R = numVertices(this)
         R = size(this.m_priorY,1);
    end
    
    %% numLabels
    
    function R = numLabels(this)
        R = size(this.m_priorY,2);
    end
    
    %% isLabeled
    
    function R = isLabeled(this, vertex_i)
        R = ismember( vertex_i, this.m_labeledSet );
    end
    
    %% priorVector
    
    function R = priorVector(this, vertex_i)
        R = this.m_priorY(vertex_i,:);
    end
    
    %% priorLabelScore
    
    function R = priorLabelScore(this, vertex_i, label_j)
        R = this.m_priorY( vertex_i, label_j );
    end
    
    %% labeledSet
    
    function R = labeledSet(this)
        R = this.m_labeledSet;
%         R = [];
%         for vertex_i=1:this.numVertices
%             if this.isLabeled( vertex_i)
%                 R = [R; vertex_i]; %#ok<AGROW>
%             end
%         end
    end

end
    
    
end

