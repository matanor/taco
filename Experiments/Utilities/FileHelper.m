classdef FileHelper
    %FILEHELPER Summary of this class goes here
    %   Detailed explanation goes here

methods (Static)
    
    %% fileName
    
    function R = fileName(fileFullPath)
        [~, R, ~] = fileparts(fileFullPath);
    end
    
    %% deleteFile
    
    function deleteFile(fileFullPath)
        if exist(fileFullPath, 'file');
            delete(fileFullPath);
        end
    end
    
    %% createDirectory
    
    function createDirectory( directoryFullPath )
        if ~exist(directoryFullPath, 'dir')
            mkdir(directoryFullPath);
        end
    end
end

end

