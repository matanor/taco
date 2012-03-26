classdef Logger
    %LOGGER Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Static)
        function log(S)
            disp( [datestr(now) '. ' S]);
        end
    end
    
end

