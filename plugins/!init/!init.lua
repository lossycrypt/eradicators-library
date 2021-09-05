-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
-- -------------------------------------------------------------------------- --

--[[ Notes:
  
  If you are a mod author who wants to use library plugin features, simply call
  the enabler function during settings or settings-updates and erlib
  will take care of everything else.
  
  Currently only 'babelfish' supports configuration, all others "just work".
  
  Usage:
    erlib_enable_plugin('plugin_name', {options})
    
  ]]

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
-- Outside of factorio '__eradicators-library__' is not a valid absolute path!
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))
  
-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local log         = elreq('erlib/lua/Log'          )().Logger  'ER:LIB'
local Loader      = elreq('plugins/!init/loader'   )(log, 'eradicators-library' )

local Set         = elreq('erlib/lua/Set'   )()
local String      = elreq('erlib/lua/String')()

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local const = require('__eradicators-library__/plugins/!init/const')

-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --
local function get_enabled_plugins(phase)
  local value
  if phase:find 'settings' then
    local db = data.raw['string-setting'][const.name.setting.enabled_plugins]
    value = db .default_value
  else
    local db = settings.startup[const.name.setting.enabled_plugins]
    value = db .value
    end
  --
  local r = Set.of_values(String.split(assert(value),'|'))
  --
  r['none'] = nil -- Remove dummy for correct table_size().
  --
  return r end
  
-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
return function(phase) assert(phase)

  -- ------------------------------------------------------------------------ --
  -- All Phases                                                               --
  -- ------------------------------------------------------------------------ --
  Loader.init(phase)
  Loader.enable_pm()

  -- ------------------------------------------------------------------------ --
  -- Settings                                                                 --
  -- ------------------------------------------------------------------------ --
  if phase == 'settings' then

    local Table   = elreq('erlib/lua/Table'       )()
    local Setting = elreq('erlib/factorio/Setting')()
      
    -- erlib_enable_plugin 
     
    local db = Setting.make {
      const.name.setting.enabled_plugins,
      'startup', 'string', 'none',
      'zz',
      allow_blank    = false,
      default_value  =  'none' ,
      allowed_values = {'none'},
      hidden         = (not flag.IS_DEV_MODE),
      }
      
    local configurators = {
      ['babelfish'] = function(options)
        assert(type(options) == 'table', 'Babelfish: Invalid options.')
        assert(type(options.search_types) == 'table', 'Babelfish: Translation types must be a table.')
        local search_types = Table.sget(db, {'babelfish_search_types'}, {})
        for _, v in pairs(options.search_types) do
          search_types[v] = true
          end
        end
      }
    
    rawset(_ENV, 'erlib_enable_plugin', function(plugin_name, options)
      -- In data stage allowed_values can not be read!
      local enabled_plugins = get_enabled_plugins(phase)
      enabled_plugins[plugin_name] = true
      local value = table.concat(Table.keys(enabled_plugins), '|')
      --
      db.default_value  =  value
      db.allowed_values = {value} -- paranoia: block changes
      log:info('Recieved request to enable plugin: "'..plugin_name..'".')
      --
      local f = configurators[plugin_name]
      if f then f(options) end
      end)


  -- ------------------------------------------------------------------------ --
  -- Settings Final Fixes                                                     --
  -- ------------------------------------------------------------------------ --
  elseif phase == 'settings-final-fixes' then

    if flag.IS_DEV_MODE then
      erlib_enable_plugin('babelfish-demo')
      erlib_enable_plugin('babelfish', {
        search_types = 
          require 'plugins/babelfish/control/SearchTypes'
          .get_supported_array()
        })
      end

    local enabled_plugins = get_enabled_plugins(phase)
    
    -- Auto-activated dependencies.
    -- (Plugins can not activate each other due to load order.)
    
    if enabled_plugins['babelfish-demo'] then
      erlib_enable_plugin('babelfish', {
        search_types = {
          -- Not too many so mod authors can test demo with
          -- their own preferred types.
          --
          -- Wrong order to test sorting.
          "recipe_name"    ,  
          "fluid_name"     ,  
          "item_name"      ,
          }
        })
      end
    
    if enabled_plugins['babelfish'] then
      erlib_enable_plugin 'on_user_panic'
      end
      
    end
    
  -- ------------------------------------------------------------------------ --
  -- All Phases                                                               --
  -- ------------------------------------------------------------------------ --

  if table_size(get_enabled_plugins(phase)) > 0 then
    Loader.enable_em()
    end

  -- Some data/ulocale-only plugins are always active.
  Loader.load_phase(get_enabled_plugins(phase))
  
  Loader.cleanup()
    
  -- ------------------------------------------------------------------------ --
  -- Control                                                                  --
  -- ------------------------------------------------------------------------ --

  if phase == 'control' then
  
    -- Failed remote interface activation test.
    -- 
    -- if flag.IS_DEV_MODE then
    --   local script = EventManager.get_managed_script('erlib-init')
    --   local SearchTypes = require 'plugins/babelfish/control/SearchTypes'
    --   script.on_event({'on_config', 'on_load'}, function()
    --     remote.call('babelfish', 'add_search_types', 
    --       SearchTypes.get_supported_set())
    --     end)
    --   end

    end
  

    
  -- ------------------------------------------------------------------------ --
  end