--[[

  The library automatically creates a number of linked-control custom inputs
  that can be shared between mods. This makes it unnessecary for every mod
  to create it's own links.

  ]]

  
-- -------------------------------------------------------------------------- --
-- Main                                                                       --
-- -------------------------------------------------------------------------- --
local _ENV = require '__eradicators-library__/erlib/Core'().Core.InstallToEnv()
Core.RunTests()


if true then return end
-- -------------------------------------------------------------------------- --
-- Draft                                                                      --
-- -------------------------------------------------------------------------- --





-- EradicatorsLibrary.Logging.override_logging_level ('ultra-verbose')
EradicatorsLibrary.Logging.set_default_logging_level ('ultra-verbose')
EradicatorsLibrary.Logging.set_log_to_stdout(true) -- print() instead of log()

EradicatorsLibrary.enable_strict_mode()
EradicatorsLibrary.install_into_environment(_ENV)




  
--to create [custom inputs] the library needs to run at least once in [data stage]

local linked_inputs = {
  'rotate' --etcpp
  }

for _,key in pairs(linked_inputs) do
  erlib.Simple.Hotkey(key,'etc pp')
  end