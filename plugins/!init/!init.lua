-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
-- -------------------------------------------------------------------------- --

--[[ Notes:
  
  If you are a mod author who wants to use library plugin features, simply call
  the enabler function during settings or settings-updates and erlib
  will take care of everything else.
  
  Currently only 'babelfish' supports configuration, all others "just work".
  
  Available functions:
    erlib_enable_plugin('plugin_name')
    erlib_configure_plugin() -- See html documentation for each plugin.
    
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

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local const = require('__eradicators-library__/plugins/!init/const')

-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --
local function get_enabled_plugins(phase)
  local Set    = elreq('erlib/lua/Set'   )()
  local String = elreq('erlib/lua/String')()
  --
  local value
  if phase:find 'settings' then
    local db = data.raw['string-setting'][const.name.setting.enabled_plugins]
    value = db .default_value
  else
    local db = settings.startup[const.name.setting.enabled_plugins]
    value = db .value
    end
  --
  local r = Set.from_values(String.split(assert(value),'|'))
  --
  r['none'] = nil -- Remove dummy for correct table_size().
  --
  return r end
  
-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
return function(phase) assert(phase)

  ------------------------------------------------------------------------------
  Loader.init(phase)

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
    
    rawset(_ENV, 'erlib_enable_plugin', function(plugin_name)
      -- In data stage allowed_values can not be read!
      local value = db.default_value..'|'..plugin_name
      db.default_value  =  value
      db.allowed_values = {value} -- paranoia: block changes
      log:raw('Recieved request to enable plugin: "'..plugin_name..'".')
      end)
    
    -- erlib_configure_plugin
    
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
    
    rawset(_ENV, 'erlib_configure_plugin', function(plugin_name, options)
      assert(configurators[plugin_name], 'Unknown plugin.')(options)
      end)
      
  -- ------------------------------------------------------------------------ --
  -- Settings Final Fixes                                                     --
  -- ------------------------------------------------------------------------ --
  elseif phase == 'settings-final-fixes' then

    if flag.IS_DEV_MODE then
      local Table = elreq('erlib/lua/Table')()
      erlib_enable_plugin('babelfish')
      erlib_configure_plugin('babelfish', {
        search_types = Table.map(
          require('plugins/babelfish/const').type_data,
          function(v) return v.type end,
          {})
        })
      end

    if get_enabled_plugins(phase)['babelfish'] then
      erlib_enable_plugin 'on_user_panic'
      end
      
    end
    
  -- ------------------------------------------------------------------------ --
  -- All Phases                                                               --
  -- ------------------------------------------------------------------------ --
  
  Loader.enable_pm()

  if table_size(get_enabled_plugins(phase)) > 0 then
    Loader.enable_em()
    end

  -- Some data/ulocale-only plugins are always active.
  Loader.load_phase(get_enabled_plugins(phase))
  
  Loader.cleanup()
    
  end