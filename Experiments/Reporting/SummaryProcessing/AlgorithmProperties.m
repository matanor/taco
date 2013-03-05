classdef AlgorithmProperties < handle
    
properties (Constant)
    MAD = SingleRun.MAD;
    AM = SingleRun.AM; 
    QC = SingleRun.QC;
    CSSL = SingleRun.CSSLMC;
end % constant

methods (Static)
    
%% algorithmColors

function R = algorithmColors()
    R{AlgorithmProperties.MAD} = 'Blue';
    R{AlgorithmProperties.AM}   = [0 0.543 0];
    R{AlgorithmProperties.QC}   = 'Cyan';
    R{AlgorithmProperties.CSSL} = 'Red';
end

%% algorithmNames

function R = algorithmNames()
    R{AlgorithmProperties.MAD}  = 'MAD';
    R{AlgorithmProperties.AM}   = 'MP';
    R{AlgorithmProperties.QC}   = 'QC';
    R{AlgorithmProperties.CSSL} = 'TACO';
end

end %static methods

end