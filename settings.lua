-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
-- Outside of factorio '__eradicators-library__' is not a valid absolute path!
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))
  
-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --
local Data  = elreq('erlib/factorio/Data/!init')()
local Table = elreq('erlib/lua/Table'     )()

-- -------------------------------------------------------------------------- --
-- Run Unit Tests                                                             --
-- -------------------------------------------------------------------------- --
if flag.DO_TESTS then
  local _ENV = require '__eradicators-library__/erlib/Core'().Core.install_to_env()
  Core.run_tests()
  end

-- -------------------------------------------------------------------------- --
-- Create Shared Hotkeys                                                      --
-- -------------------------------------------------------------------------- --

-- if true then return end





-- -------------------------------------------------------------------------- --
-- Draft                                                                      --
-- -------------------------------------------------------------------------- --

local function make_enabler(prototype)
  return function() data.raw['bool-setting'][prototype.name].forced_value = true end
  end
  
local dummy = {
  type          = 'bool-setting' ,
  setting_type  = 'startup'      ,
  order         = 'zz'           ,
  hidden        = true           ,
  default_value = false          ,
  forced_value  = false          , -- Only loaded if hidden = true
  }

_ENV .erlib_enable_bablefish = make_enabler(
  Data.Inscribe(Table.smerge(dummy, {
    name  = 'erlib:enable-babelfish',
    order = 'ZZ9 Plural Z Alpha'    ,
    }))
  )

_ENV .erlib_enable_cursor_tracker = make_enabler(
  Data.Inscribe(Table.smerge(dummy,{name  = 'erlib:enable-cursor-tracker'}))
  )

