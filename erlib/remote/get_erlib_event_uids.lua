-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Numeric event names for Erlib custom events.
--
-- Requiring this file returns a table
-- mapping {event_name -> event_number}, just like defines.events.
-- The numbers are dynamically generated so they may change
-- every time you start the game, change mods, etc..
--
-- @module get_erlib_event_uids
-- @usage
--  defines.erlib_events
--    = require('__eradicators-library__/erlib/remote/get_erlib_event_uids')
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local UID_INTERFACE_NAME = 'eradicators-library:custom-event-uids'
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- Because this is a "remote" file it directly returns the desired table.
-- -------------------------------------------------------------------------- --
return elreq('erlib/factorio/Remote')().PackedInterfaceGroup(UID_INTERFACE_NAME):get_all()
