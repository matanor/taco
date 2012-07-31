classdef Logger
    %LOGGER Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Static)
        function log(S)
            fprintf( [datestr(now) '. ' S '\n']);
        end
    end
    
end

