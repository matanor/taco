classdef ConfigManager < handle
    %CONFIGREADER Summary of this class goes here
    %   Detailed explanation goes here
    
properties
    m_configFullPath;
end
    
methods (Access = private)
    function this = ConfigManager(configFullPath)
        if nargin > 0 && ~isempty(configFullPath)
            ConfigManager.static('set',configFullPath);
        end
        this.m_configFullPath = ConfigManager.static('get');
    end
end

methods
    function R = read(this)
        fileData = load(this.m_configFullPath);
        R = fileData.config;
    end
    
    function write(this, config) %#ok<INUSD>
        save(this.m_configFullPath, 'config');
    end
    
    function createWithDefaultsIfMissing(this)
        if ~exist(this.m_configFullPath, 'file')
            this.createWithDefaults();
        end
    end
    
    function createWithDefaults(this)
        Logger.log(['Creating default config file at ' this.m_configFullPath]);
        config.maxJobs = 60;
        config.jobTimeoutInMinutes = 10;
        this.write(config);
    end
    
end

methods (Static)
    function init(configFileFullPath)
        ConfigManager(configFileFullPath);
    end
    
    function R = get()
        R = ConfigManager();
    end
    
    function R = static(op, argument)
        persistent static_data;
        if 1 == strcmp(op,'get')
            R = static_data;
        elseif 1 == strcmp(op,'set')
            static_data = argument;
        else
            Logger.log(['unknown operation ''' op '''' ]);
        end
    end
end
    
end

