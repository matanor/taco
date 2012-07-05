classdef ConfigManager < handle
    %CONFIGREADER Summary of this class goes here
    %   Detailed explanation goes here
    
properties
    m_configFullPath;
end
    
methods (Access = private)
    
    %% ConfigManager
    
    function this = ConfigManager(configFullPath)
        if nargin > 0 && ~isempty(configFullPath)
            ConfigManager.static('set',configFullPath);
        end
        this.m_configFullPath = ConfigManager.static('get');
    end
    
    %% createWithDefaultsIfMissing
    
    function createWithDefaultsIfMissing(this)
        if ~exist(this.m_configFullPath, 'file')
            this.createWithDefaults();
        end
    end
    
    %% createWithDefaults
    
    function createWithDefaults(this)
        Logger.log(['Creating default config file at ' this.m_configFullPath]);
        config.maxJobs.mem_queue = 0;
        config.maxJobs.all_queue = 60;
        config.isOnOdin = 0;
        config.jobTimeoutInMinutes = 10;
        this.write(config);
    end
    
end

methods
    
    %% read
    
    function R = read(this)
        assert(~isempty(this.m_configFullPath));
        fileData = load(this.m_configFullPath);
        R = fileData.config;
    end
    
    %% write
    
    function write(this, config) %#ok<INUSD>
        assert(~isempty(this.m_configFullPath));
        save(this.m_configFullPath, 'config');
    end
    
end

methods (Static)
    
    %% initOnDesktop
    
    function initOnDesktop()
        ConfigManager.init('C:/technion/theses/matlab/config.mat');
    end
    
    %% init
    
    function init(configFileFullPath)
        configManager = ConfigManager(configFileFullPath);
        configManager.createWithDefaultsIfMissing();
    end
    
    %% get
    
    function R = get()
        R = ConfigManager();
    end
    
    %% static
    
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

