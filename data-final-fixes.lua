--[[

  The library automatically creates a number of linked-control custom inputs
  that can be shared between mods. This makes it unnessecary for every mod
  to create it's own links.

  ]]

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
Data.SimpleCustomInput('er:','interact-button','mouse-button-3')

-- -------------------------------------------------------------------------- --
-- Plugins                                                                      --
-- -------------------------------------------------------------------------- --
if settings.startup['erlib:enable-cursor-tracker'].value then
  require 'plugins/cursor-tracker/data-final-fixes.lua'
  end


-- -------------------------------------------------------------------------- --
-- Draft                                                                      --
-- -------------------------------------------------------------------------- --

