-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
-- Outside of factorio '__eradicators-library__' is not a valid absolute path!
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))
  
-- -------------------------------------------------------------------------- --


-- -------------------------------------------------------------------------- --
return function(phase) assert(phase)

  --[[
    
    If you are a mod author who wants to use library hook features, simply call
    one of these enabler functions during settings or settings-updates, erlib
    will take care of everything else.
    
    Available functions:
      erlib_enable_plugin('babelfish')
      erlib_enable_plugin('cursor-tracker') -- to be implemented...
      erlib_enable_plugin('zoom_tracker')   -- to be implemented...
      
    ]]

  local const = require('__eradicators-library__/plugins/!init/const')

  local function get_enabled_plugins(setting)
    -- allowed_values can not be read in data stage
    local Set    = elreq('erlib/lua/Set'   )()
    local String = elreq('erlib/lua/String')()
    return Set.from_values(
      String.split(assert(setting.value or setting.default_value),'|')
      )
    end
    
  -- ------------------------------------------------------------------------ --
  -- Debug                                                                    --
  -- ------------------------------------------------------------------------ --
    
  if flag.IS_DEV_MODE then
    _ENV.Hydra = elreq('erlib/lua/Coding/Hydra')()
    end
    
  -- ------------------------------------------------------------------------ --
  -- Sanity                                                                   --
  -- ------------------------------------------------------------------------ --
  
  if phase ~= 'control' then
    -- Detect when another mod accidentially left PM active.
    assert(_ENV.PluginManager == nil, 'Foreign PluginManager detected in _ENV!')
    end
    
  -- ------------------------------------------------------------------------ --
  -- Settings                                                                 --
  -- ------------------------------------------------------------------------ --
  if phase == 'settings' then

    local Setting = elreq('erlib/factorio/Setting')()
    local Table   = elreq('erlib/lua/Table'       )()
      
    local db = Setting.make {
      const.name.setting.enabled_plugins,
      'startup', 'string', 'none',
      'zz',
      allow_blank    = false,
      allowed_values = {'none'},
      hidden         = (not flag.IS_DEV_MODE),
      }
    
    _ENV .erlib_enable_plugin = function(plugin_name)
      local value = db.default_value..'|'..plugin_name
      db.default_value  = value
      db.allowed_values = {value}
      log('Recieved request to enable plugin: "'..plugin_name..'".')
      -- print(debug.traceback())
      end
    
    local configurators = {
      ['babelfish'] = function(options)
        assert(type(options) == 'table', 'Babelfish: Invalid options.')
        assert(type(options.search_types) == 'table', 'Babelfish: Translation types must be a table.')
        local search_types = Table.sget(db, {'babelfish_search_types'}, {})
        for _, v in pairs(options.search_types) do
          table.insert(search_types, v)
          end
        end
      }
    
    _ENV .erlib_configure_plugin = function(plugin_name, options)
      assert(configurators[plugin_name], 'Unknown plugin.')(options)
      end
      
  -- ------------------------------------------------------------------------ --
  -- Settings Final Fixes                                                     --
  -- ------------------------------------------------------------------------ --
  elseif phase == 'settings-final-fixes' then

    local Table = elreq('erlib/lua/Table')()
    local Set   = elreq('erlib/lua/Set'  )()
    
    local db = data.raw['string-setting'][const.name.setting.enabled_plugins]
    local enabled_plugins = get_enabled_plugins(db)
    
    if flag.IS_DEV_MODE then
      erlib_enable_plugin('babelfish')
      erlib_configure_plugin('babelfish', {
        search_types = Table.map(
          require('plugins/babelfish/const').type_data,
          function(v) return v.type end,
          {})
        })
      end
  
    if enabled_plugins['babelfish'] then
      require 'plugins/babelfish/settings-final-fixes' (
        assert(Table.pop(db, 'babelfish_search_types'))
        )
      end

  -- ------------------------------------------------------------------------ --
  -- Data Final Fixes                                                         --
  -- ------------------------------------------------------------------------ --
  elseif phase == 'data-final-fixes' then

    local db = settings.startup[const.name.setting.enabled_plugins]
    local enabled_plugins = get_enabled_plugins(db)
  
    if true then -- Does this need a condition?
      require 'plugins/tips-group/data-final-fixes'
      end
      
    if enabled_plugins['cursor-tracker'] then
      require 'plugins/cursor-tracker/data-final-fixes.lua'
      end
    
    if enabled_plugins['babelfish'] then
      require 'plugins/babelfish/data-final-fixes'
      end
      
  -- ------------------------------------------------------------------------ --
  -- Control                                                                  --
  -- ------------------------------------------------------------------------ --
  elseif phase == 'control' then

    -- ---------------------------------------------------------------------- --
    -- Generic Ulocale                                                        --
    -- ---------------------------------------------------------------------- --
    require 'plugins/tips-group/ulocale'
    require 'plugins/!init/ulocale'
  
    -- ---------------------------------------------------------------------- --
    -- Hooks & Nooks                                                          --
    -- ---------------------------------------------------------------------- --
      
    local Set   = elreq('erlib/lua/Set'  )()
    
    local db = _ENV.settings.startup[const.name.setting.enabled_plugins]
    local enabled_plugins = get_enabled_plugins(db)
    -- ignore dummies
    enabled_plugins[''    ] = nil
    enabled_plugins['none'] = nil
      
    -- When *at least one* plugin has been requested.
    for v, _ in pairs(enabled_plugins) do if v then

      _ENV. PluginManager = require ('erlib/factorio/PluginManagerLite-1')()
      _ENV. EventManager  = require ('erlib/factorio/EventManagerLite-1' )()
      require ('erlib/lua/Lock')().AutoLock(_ENV, '_ENV', 'GLOBAL')

      PluginManager.enable_savedata_management()

      if enabled_plugins['babelfish'] then
        require 'plugins/babelfish/control.lua'
        -- Creating the locale needs access to 
        -- the settings_prototype.default_value
        require 'plugins/babelfish/ulocale'
        end
      
      if enabled_plugins['on_ticked_action'] then
        require 'plugins/on_ticked_action/control.lua'
        end
      
      if enabled_plugins['on_player_changed_chunk'] then
        require 'plugins/on_player_changed_chunk/control.lua'
        end
        
      if enabled_plugins['on_user_panic'] then
        require 'plugins/on_user_panic/control'
        require 'plugins/on_user_panic/ulocale'
        end

      if enabled_plugins['on_entity_created'] then
        require 'plugins/on_entity_created/control'
        end
        
      if enabled_plugins['gui-auto-styler'] then
        require 'plugins/gui-auto-styler/control'
        end
        
      break end end
      
    end
    
  end