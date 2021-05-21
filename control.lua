-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
-- Outside of factorio '__eradicators-library__' is not a valid absolute path!
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))
  
-- -------------------------------------------------------------------------- --
-- Run Unit Tests                                                             --
-- -------------------------------------------------------------------------- --
if flag.DO_TESTS then
  local _ENV = require 'erlib/Core'().Core.install_to_env()
  Core.run_tests()
  end

-- -------------------------------------------------------------------------- --
-- Plugins                                                                    --
-- -------------------------------------------------------------------------- --

local settings = {
  enable_bablefish      = settings.startup['erlib:enable-babelfish'     ].value,
  enable_cursor_tracker = settings.startup['erlib:enable-cursor-tracker'].value,
  enable_zoom_tracker   = settings.startup['erlib:enable-zoom-tracker'  ].value,
  }
  
-- When at least one plugin has been requested.
local ok; for _,v in pairs(settings) do ok=ok or v end if ok then

  _ENV. PluginManager = elreq ('erlib/factorio/PluginManagerLite-1')()
  _ENV. EventManager  = elreq ('erlib/factorio/EventManagerLite-1' )()
  elreq ('erlib/lua/Lock')().AutoLock(_ENV, '_ENV', 'GLOBAL')

  PluginManager.enable_savedata_management()

  if settings.enable_bablefish then require('plugins/babelfish/control.lua') end
  
  end


-- -------------------------------------------------------------------------- --
-- Draft                                                                      --
-- -------------------------------------------------------------------------- --
