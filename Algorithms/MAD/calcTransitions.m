function transitions = calcTransitions( neighboursWeigths )
%CALCTRANSITIONS Calculate transition probabilitis from neighbours weights
%   Detailed explanation goes here

    s = sum( neighboursWeigths );
    transitions = neighboursWeigths / s;

end

