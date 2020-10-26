-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Numeric event names for Erlib custom events.
--
-- Requiring this file returns a table
-- mapping {event_name -> event_number}, just like defines.events.
-- The numbers are dynamically generated so they may change
-- every time you start the game, change mods, etc..
--
-- @set sort=true
--
-- @module Remote.EventNames
-- @usage
--  defines.custom_events = require('__eradicators-library__/erlib/remote/shared_event_uids')
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

-- local Stacktrace = elreq('erlib/factorio/Stacktrace')()
-- local load_phase = Stacktrace.get_load_phase

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

-- local SharedEventUID,_SharedEventUID,_uLocale = {},{},{}

local UID_INTERFACE_NAME = 'eradicators-library:custom-event-uids'

--------------------------------------------------------------------------------
-- Events.
-- @section
--------------------------------------------------------------------------------


-- -------------------------------------------------------------------------- --
-- Create UIDs                                                                --
-- -------------------------------------------------------------------------- --


-- Event UIDs that should be shared by all library instances.
if flag.IS_LIBRARY_MOD then
-- if Stacktrace.get_mod_name(-1) == 'eradicators-library' then

  local uids = {}
  remote.add_interface(UID_INTERFACE_NAME, uids)

  -- add a new "124;name" dummy to the list
  local function new_uid(name)
    uids[ script.generate_event_name() .. ';' .. name] = ercfg.SKIP
    end


  ----------
  -- Raised when the researched state of a technology has changed from true to
  -- false. For example because another mod called @{FOBJ LuaForce.reset}.
  -- 
  -- @tfield LuaTechnology research
  --
  -- @table on_research_reset
  --
  new_uid 'on_research_reset'


  ----------
  -- Raised when the player moves or is teleported across a chunk border.
  -- This is a higher-resolution abstraction of @{FAPI events on_player_changed_position}.
  -- 
  -- @tfield uint player_index
  -- @tfield ChunkPosition old_chunk
  -- @tfield ChunkPosition new_chunk
  --
  -- @table on_player_changed_chunk
  --
  new_uid 'on_player_changed_chunk'
  

  end

  
-- -------------------------------------------------------------------------- --
-- Get UIDs                                                                   --
-- -------------------------------------------------------------------------- --


-- -------
-- Gets ErLib custom event names. Creates a fresh table every time.
-- 
-- @treturn table A table in the same format as defines.events, mapping
-- each custom event name string to its event name number.
-- 
local function get_custom_event_uids()

  local event_uids = {}
  
  -- Extracts event uids from the remote interface dummy names.
  for str in pairs(remote.interfaces[UID_INTERFACE_NAME]) do
    local uid, name  = str:match('(%d+);(.+)')
    event_uids[name] = tonumber(uid)
    end

  return event_uids
    
  end
  
  
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
-- Because this is a "remote" file it directly returns the desired table.
return get_custom_event_uids()
