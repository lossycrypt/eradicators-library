

  
-- -------------------------------------------------------------------------- --
-- Main                                                                       --
-- -------------------------------------------------------------------------- --
local _ENV = require '__eradicators-library__/erlib/Core'().Core.install_to_env()
Core.run_tests()

-- Log testing
local log = Log.Logger('testlogger')
log:warn('warn') log:info('info') log:debug('deb') log:say('say')

-- Create shared event uids
require('__eradicators-library__/erlib/remote/shared_event_uids')


-- -------------------------------------------------------------------------- --
-- Draft (Custom Event UIDs)                                                  --
-- -------------------------------------------------------------------------- --

--[[
-- Event UIDs that should be shared by all library instances.
local SKIP = function()end
local uids = {}
remote.add_interface('eradicators-library:custom-event-uids', uids)

local function new_uid(name)
  -- local r = {
    -- name = name,
    -- uid  = script.generate_event_name()
    -- }
  -- uids[ serpent.line(r, {compact=true}) ] = SKIP
  uids[ name .. ';' .. script.generate_event_name() ] = SKIP
  end

new_uid 'on_research_reset'
new_uid 'on_player_changed_chunk'
--]]

-- -------------------------------------------------------------------------- --
-- Draft                                                                      --
-- -------------------------------------------------------------------------- --



if true then return end
-- -------------------------------------------------------------------------- --
-- Garbage                                                                    --
-- -------------------------------------------------------------------------- --


  
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