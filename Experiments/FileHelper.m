classdef FileHelper
    %FILEHELPER Summary of this class goes here
    %   Detailed explanation goes here

methods (Static)
    function R = fileName(fileFullPath)
        [~, R, ~] = fileparts(fileFullPath);
    end
end

end

