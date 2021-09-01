-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Methods for
-- [Mod Settings](https://wiki.factorio.com/Tutorial:Mod_settings).
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Setting
-- @usage
--  local Setting = require('__eradicators-library__/erlib/factorio/Setting')()


--------------------------------------------------------------------------------
-- Concepts.
-- @section
--------------------------------------------------------------------------------

--[[------

  Factorio uses several different names for the `setting_type` of a setting.

    In-Game Menu | Erlib     | settings.lua      | data.lua  | LuaSettings
    ---------------------------------------------------------------------
    Startup      | 'startup' | 'startup'         | 'startup' | 'startup'
    Map          | 'map'     | 'runtime-global'  |  -        | 'global'
    Per Player   | 'player'  | 'runtime-per-user'|  -       '| 'player'

 @table setting_type
--]]
do end
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local log        = elreq('erlib/lua/Log'       )().Logger  'Settings'
local stop       = elreq('erlib/lua/Error'     )().Stopper 'Settings'

local Table      = elreq('erlib/lua/Table'     )()
local Tool       = elreq('erlib/lua/Tool'      )()

local Stacktrace = elreq('erlib/factorio/Stacktrace')()
local is_control = Stacktrace.get_load_stage().control and true

local Verificate = elreq('erlib/lua/Verificate')()
local verify     = Verificate.verify

local Player     = elreq('erlib/factorio/Player')()

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Setting,_Setting,_uLocale = {},{},{}



--------------------------------------------------------------------------------
-- Setting.
-- @section
--------------------------------------------------------------------------------


-- DATA
if Stacktrace.get_load_stage().data then
 
  ---------
  -- Retrieve the current value of a @{FAPI Concepts ModSetting}.
  -- 
  -- Works in: data stage, control stage.
  -- 
  -- @tparam string|player_index|LuaPlayer setting_type The string can be
  -- either `'startup'` or `'map'`. Only `'startup'` is valid in data stage.
  -- @tparam string name Name of the setting.
  -- 
  -- @treturn NotNil Value of the setting.
  -- 
  function Setting.get_value(setting_type, name)
    -- only startup exists in data stage
    assert(setting_type == 'startup', 'Invalid setting type.')
    return assert(settings.startup[name], 'Invalid name: '..name ).value
    end
    
  ---------
  -- Set a new value for a @{FAPI Concepts ModSetting}. Works only
  -- when called from the same mod that created the setting.
  --
  -- Works in: control stage.
  --
  -- See also @{FOBJ LuaSetting }
  --
  -- @tparam string|player_index|LuaPlayer setting_type The string can be
  -- either `'startup'` or `'map'`. Only `'startup'` is valid in data stage.
  -- @tparam string name Name of the setting.
  --
  function Setting.set_value(setting_type, name)
    stop('Can not write settings during data stage.')
    end
  
  end
  
-- CONTROL
if Stacktrace.get_load_stage().control then

  -- Documentation above is for both stage variants.
  
  local types = {startup = 'startup', map = 'global'}
  local msg = 'Invalid setting name: '
  
  local function get_table(setting_type)
    if type(setting_type) == 'string' then
      return settings[
        verify(types[setting_type], 'string',
        'Invalid setting type. ', setting_type)
        ]
    else
      return Player.get_player(setting_type).mod_settings
      end
    end
  
  function Setting.get_value(setting_type, name)
    return assert(get_table(setting_type)[name], msg..name).value
    end
    
  function Setting.set_value(setting_type, name, value)
    local tbl = get_table(setting_type)
    assert(tbl[name], msg..name) 
    tbl[name] = {value = value}
    end
  
  end
   

if Stacktrace.get_load_stage().settings then

  --[[-----
  Syntactic sugar for making settings.

  @usage
    Setting.make {
      'mymod-my-setting-name',
      'player', 'string', 'default_value',
      'order-string-[foo]-[bar]',
      allow_blank    = false,
      allowed_values = {'default_value', 'other_value'},
      }
  
  @tparam table prototype (@{table})
  @tparam string prototype.1 name
  @tparam string prototype.2 @{Setting.setting_type|setting_type}
  @tparam string prototype.3 type `'bool'`, `'int'`, `'string'` or `'double'`
  @tparam boolean|number|string|table prototype.4 default_value  
  Can also be a table `{minimum_value, default_value, maximum_value}`
  @tparam string prototype.5 order
  @tparam AnyValue prototype.... Everything else is copied unchanged.
    
  @treturn table A reference to the new prototype at `data.raw[type][name]`.
    
  @function Setting.make
  ]]
  
  local translate_scope = setmetatable({
    startup = 'startup',
    map     = 'runtime-global',
    player  = 'runtime-per-user',
    },
    {__index = function(_,k) return k end}
    )
    
  function Setting.make(args)
    args = Table.dcopy(args) -- Removes need to document in-place changing...
      
    args.name          = args.name or args[1]
    args.setting_type  = translate_scope[args.setting_type or args[2]]
    -- bool, int, string, double
    args.type          = (args.type or args[3]):gsub('%-setting','')..'-setting'
    -- false is valid too!
    args.default_value = Tool.First(args.default_value, args[4])
      
    args.order         = args.order or args[5]

    if type(args.default_value) == 'table' then
      args.maximum_value = args.default_value[3]
      args.minimum_value = args.default_value[1]
      args.default_value = args.default_value[2]
      end
      
    for i=1,5 do args[i] = nil end
      
    log:debug('Created new simple setting:', args.name)
    data:extend{args}
    return args end

  end

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Setting') end
return function() return Setting,_Setting,_uLocale end
