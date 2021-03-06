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
-- Create Shared Hotkeys                                                      --
-- -------------------------------------------------------------------------- --
local Data = elreq('erlib/factorio/Data/!init')()
Data.SimpleCustomInput('er:','interact','mouse-button-3')

-- -------------------------------------------------------------------------- --
-- Plugins                                                                      --
-- -------------------------------------------------------------------------- --
require('plugins/!init/!init.lua')('data-final-fixes')

-- -------------------------------------------------------------------------- --
-- Draft                                                                      --
-- -------------------------------------------------------------------------- --

