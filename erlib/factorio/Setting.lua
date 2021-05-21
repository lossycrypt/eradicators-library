-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Methods for
-- @{URL https://wiki.factorio.com/Tutorial:Mod_settings|Mod Settings}.
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
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local log        = elreq('erlib/lua/Log'       )().Logger  'Settings'
local stop       = elreq('erlib/lua/Error'     )().Stopper 'Settings'

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
  -- Available in data and control stage only.
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
    return settings.startup[name].value
    end
    
  ---------
  -- Set a new value for a @{FAPI Concepts ModSetting}. Works only
  -- when called from the same mod that created the setting.
  --
  -- @tparam string|player_index|LuaPlayer setting_type The string can be
  -- either `'startup'` or `'map'`. Only `'startup'` is valid in data stage.
  -- @tparam string name Name of the setting.
  --
  -- Available in control stage only.
  --
  -- See also @{FOBJ LuaSetting }
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
   



-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Setting') end
return function() return Setting,_Setting,_uLocale end
