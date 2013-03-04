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
    
    %% removeDirectotyAndContents
    
    function removeDirectoryAndContents(directoryPath)
        if exist(directoryPath, 'dir');
            rmdir(directoryPath,'s');
        end
    end 
    
    %% createDirectory
    
    function createDirectory( directoryFullPath )
        if ~exist(directoryFullPath, 'dir')
            mkdir(directoryFullPath);
        end
    end
    
    %% addFileNameSuffix
    
    function R = addFileNameSuffix(fileFullPath, suffix)
        [path, name, ext] = fileparts(fileFullPath);
        R = [path '/' name suffix ext];
    end
    
    %% getFolder
    
    function R = getFolder(fileFullPath)
        [path, ~, ~] = fileparts(fileFullPath);
        R = path;
    end
    
    %% hasSubDirs
    
    function R = hasSubDirs( files )
        R = 0;
        numFiles = length(files);
        for file_i=1:numFiles
            if files(file_i).isdir && ...
               files(file_i).name(1) ~= '.' 
                R = 1;
                break;
            end
        end
    end
    
    %% CopyFileRenameIfExists
    
    function CopyFileRenameIfExists(sourceFullPath, destinationFullPath)
        suffix_i = 2;
        while exist(destinationFullPath,'file')
            suffix = num2str(suffix_i);
            destinationFullPath = FileHelper.addFileNameSuffix...
                (destinationFullPath, ['_' suffix]);
        end
        destinationFolder = FileHelper.getFolder(destinationFullPath);
        FileHelper.createDirectory(destinationFolder);
        FileHelper.CopyFile(sourceFullPath, destinationFullPath);
    end
    
    %% CopyFile
    
    function CopyFile(sourceFullPath, destinationFullPath)
        Logger.log(['::CopyFile. Copying from ''' sourceFullPath ''''...
                    ' to '''  destinationFullPath ]);
        if ~exist(sourceFullPath,'file')
            Logger.log('::CopyFile. Source is missing');
        end
        [status, message] = copyfile(sourceFullPath, destinationFullPath );        
        if (status ~= 1)
            Logger.log(['::CopyFile. Error = ' message]);
        end
    end
end

end

