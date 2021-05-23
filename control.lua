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
-- Universal Locale                                                           --
-- -------------------------------------------------------------------------- --
require 'erlib/ulocale'
  
-- -------------------------------------------------------------------------- --
-- Plugins                                                                    --
-- -------------------------------------------------------------------------- --
require('plugins/!init/!init.lua')('control')

-- -------------------------------------------------------------------------- --
-- Reserved Commands                                                          --
-- -------------------------------------------------------------------------- --
-- Reserve commands for later use with on_console_command to
-- prevent "unknown command" error message.
commands.add_command('er'       , '', ercfg.SKIP)
commands.add_command('erlib'    , '', ercfg.SKIP)
commands.add_command('babelfish', '', ercfg.SKIP)


-- -------------------------------------------------------------------------- --
-- Draft                                                                      --
-- -------------------------------------------------------------------------- --
