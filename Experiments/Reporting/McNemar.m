classdef McNemar
    %MCNEMAR Summary of this class goes here
    %   Detailed explanation goes here
    
properties
end
    
methods (Static)

%% test
    
function test()    
    correct =       [1 1 1 0 0 ];
    prediction_a =  [0 0 1 1 1 ];
    prediction_b =  [1 0 1 0 0 ];
    McNemar.calculate(correct, prediction_a, prediction_b);
end
    
%% calculate
    
function calculate(correct, prediction_a, prediction_b)

    a_correct = (correct == prediction_a);
    b_correct = (correct == prediction_b);

    n00 = sum( ((a_correct == 0) .* (b_correct == 0)) ) ;
    n01 = sum( ((a_correct == 0) .* (b_correct == 1)) ) ;
    n10 = sum( ((a_correct == 1) .* (b_correct == 0)) ) ;
    n11 = sum( ((a_correct == 1) .* (b_correct == 1)) ) ;

    a_accuracy = (n10 + n11) / (n10 + n11 + n01 + n00);
    b_accuracy = (n01 + n11) / (n10 + n11 + n01 + n00);

    numer = (abs(n01 - n10) - 1)^2;

    denom = n01 + n10;
    total = 0;
    if (denom ~= 0)
        total = numer / denom;
    end

    if (n01 + n10 < 10)
        disp( 'Number of disagreements are small so may not be reliable.' );
    end

    disp([ 'Total: ' num2str(total)]);

    disp([ 'Accuracy: File A: ' num2str(1.0 - a_accuracy) ', File B: ' num2str(1.0 - b_accuracy) ]);
    significant = 0;
    if (total > 3.841459)
        significant = 1;
        disp('Significant at P=.05');
        if (total > 6.64) 
            disp('Significant at P=.01');
        end
        if (total > 10.83)
            disp('Significant at P=.001');
        end
    end

    disp(['Results significant according to McNemar''''s test: ' num2str(significant)]);
    if (a_accuracy > b_accuracy) 
        disp('Better system: A ');
    elseif (a_accuracy < b_accuracy) 
        disp('Better system: B ');
    else
        disp('System performance the same.');
    end
end
    
end % static methods

end % classdef

