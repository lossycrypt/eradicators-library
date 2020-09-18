--[[

  The library automatically creates a number of linked-control custom inputs
  that can be shared between mods. This makes it unnessecary for every mod
  to create it's own links.

  ]]

  
-- local StopLib = require 'erlib/lua/Stop' ()
-- StopLib.Error('MyModName','MyScript',"Sorry, i can't do that Dave!")


local flag = pcall(require,'__zz-toggle-to-enable-dev-mode__/empty')


-- collective loading of all modules without changing _ENV
local EradicatorsLibrary = require '__eradicators-library__/erlib/Core'()



if true then return end

-- EradicatorsLibrary.Logging.override_logging_level ('ultra-verbose')
EradicatorsLibrary.Logging.set_default_logging_level ('ultra-verbose')
EradicatorsLibrary.Logging.set_log_to_stdout(true) -- print() instead of log()

EradicatorsLibrary.enable_strict_mode()
EradicatorsLibrary.install_into_environment(_ENV)





local erlib = require '__eradicators-library__/erlib/library.lua' (_ENV,{
  is_dev_build = flag,
  debug_mode   = flag,
  strict_mode  = flag,
  verbose      = flag,
  })

  
--to create [custom inputs] the library needs to run at least once in [data stage]

local linked_inputs = {
  'rotate' --etcpp
  }

for _,key in pairs(linked_inputs) do
  erlib.Simple.Hotkey(key,'etc pp')
  end