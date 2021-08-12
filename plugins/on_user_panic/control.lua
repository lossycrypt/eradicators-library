-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description is ignored for submodules.
--
-- @module EventManagerLite

--[[ Notes:
  ]]

--[[ Annecdotes:
  ]]

--[[ Future:
  ]]
  
--[[ Todo:
  ]]
  
-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local script = EventManager .get_managed_script    'on_user_panic'
local on_user_panic = script.generate_event_name 'on_user_panic'

-- -------------------------------------------------------------------------- --
-- Events                                                                     --
-- -------------------------------------------------------------------------- --

----------
-- Raised when a player calls `"DON'T PANIC!"` in the chat.
-- You should trigger some generic sanity checking and garbage
-- collection of your mods internal state now.
-- 
-- Abstract:
-- @{FAPI events on_console_chat}  
--
-- @usage
--   script.on_event(EventManager.events.on_user_panic, function(e)
--     dostuff()
--     Player.get_event_player(e).print{e.calming_words, 'name-of-your-content'}
--     end)
-- 
-- @tfield[opt] uint player_index Commands typed on the server console do
-- not have a `player_index`.
-- @tfield string message
-- @tfield string calming_words The key for the localised string you
-- should print when you're done.
--
-- @within ExtraEvents
-- @table on_user_panic

script.on_event(defines.events.on_console_chat, function(e)
  if e.message == "DON'T PANIC!" then
    e.calming_words = 'er.dont-panic-calming-words'
    script.raise_event(on_user_panic, e)
    end
  end)


