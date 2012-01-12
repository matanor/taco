classdef CSSLBase < handle
% Base class for CSSL algorithms

    properties (SetAccess=public, GetAccess=protected)
        m_W;
        m_num_iterations;
        m_alpha;
        m_beta;
        m_labeledConfidence;
    end
    
end

