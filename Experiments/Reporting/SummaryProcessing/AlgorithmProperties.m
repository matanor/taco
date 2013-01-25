classdef AlgorithmProperties < handle
    
properties (Constant)
    MAD = 1;
    AM = 2; 
    QC = 3;
    CSSL = 4;
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