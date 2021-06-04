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

    local Data  = elreq('erlib/factorio/Data/!init')()
    local Table = elreq('erlib/lua/Table'     )()
    
    local enablers = {}
    local function make_enableable(name, prototype)
      enablers[name] = prototype
      end
    
    _ENV .erlib_enable_plugin = function(plugin_name)
      local prototype = assert(enablers[plugin_name], 'Unknown plugin')
      data.raw['bool-setting'][prototype.name].forced_value = true
      log(prototype.name:gsub('.*enable%-','') .. ' was enabled.')
      end
    
    local configurators = {
      ['babelfish'] = function(options)
        assert(type(options) == 'table', 'Babelfish: Invalid options.')
        assert(type(options.search_types) == 'table', 'Babelfish: Translation types must be a table.')
        for _, v in pairs(options.search_types) do
          table.insert(enablers['babelfish'].search_types, v)
          end
        end
      }
    
    _ENV .erlib_configure_plugin = function(plugin_name, options)
      assert(configurators[plugin_name], 'Unknown plugin.')(options)
      end
    
    local dummy = {
      type          = 'bool-setting' ,
      setting_type  = 'startup'      ,
      order         = 'zz'           ,
      hidden        = true           ,
      default_value = false          ,
      forced_value  = false          , -- Only loaded if hidden = true
      }

    make_enableable('babelfish',
      Data.Inscribe(Table.smerge(dummy, {
        name  = 'erlib:enable-babelfish',
        order = 'ZZ9 Plural Z Alpha'    ,
        search_types = {}               , -- delete later
      })))

    make_enableable('cursor-tracker',
      Data.Inscribe(Table.smerge(dummy,{
        name  = 'erlib:enable-cursor-tracker',
      })))

    make_enableable('zoom-tracker',
      Data.Inscribe(Table.smerge(dummy,{
        name  = 'erlib:enable-zoom-tracker',
      })))
      
  -- ------------------------------------------------------------------------ --
  -- Settings Final Fixes                                                     --
  -- ------------------------------------------------------------------------ --
  elseif phase == 'settings-final-fixes' then

    local Table = elreq('erlib/lua/Table')()
    
    if flag.IS_DEV_MODE then
      erlib_enable_plugin('babelfish')
      erlib_configure_plugin('babelfish', {
        search_types = Table.map(
          require('plugins/babelfish/const').type_data,
          function(v) return v.type end,
          {})
        })
      end
  
    if data.raw['bool-setting']['erlib:enable-babelfish'].forced_value then
      require 'plugins/babelfish/settings-final-fixes' (Table.pop(
          data.raw['bool-setting']['erlib:enable-babelfish'],'search_types'
        ))
      end

  -- ------------------------------------------------------------------------ --
  -- Data Final Fixes                                                         --
  -- ------------------------------------------------------------------------ --
  elseif phase == 'data-final-fixes' then

    if true then -- Does this need a condition?
      require 'plugins/tips-group/data-final-fixes'
      end
      
    if settings.startup['erlib:enable-cursor-tracker'].value then
      require 'plugins/cursor-tracker/data-final-fixes.lua'
      end
    
    if settings.startup['erlib:enable-babelfish'].value then
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
  
    -- ---------------------------------------------------------------------- --
    -- Hooks & Nooks                                                          --
    -- ---------------------------------------------------------------------- --
    local function f(n) return _ENV.settings.startup[n].value end
    local settings = {
      enable_bablefish      = f 'erlib:enable-babelfish'     ,
      enable_cursor_tracker = f 'erlib:enable-cursor-tracker',
      enable_zoom_tracker   = f 'erlib:enable-zoom-tracker'  ,
      }
      
    -- When *at least one* plugin has been requested.
    for _, v in pairs(settings) do if v then

      _ENV. PluginManager = require ('erlib/factorio/PluginManagerLite-1')()
      _ENV. EventManager  = require ('erlib/factorio/EventManagerLite-1' )()
      require ('erlib/lua/Lock')().AutoLock(_ENV, '_ENV', 'GLOBAL')

      PluginManager.enable_savedata_management()

      if settings.enable_bablefish then
        require 'plugins/babelfish/control.lua'
        -- Creating the locale needs access to 
        -- the settings_prototype.default_value
        require 'plugins/babelfish/ulocale'
        end
      
      break end end
      
    end
    
    
  end