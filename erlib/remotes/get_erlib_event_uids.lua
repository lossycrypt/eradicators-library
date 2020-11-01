-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- @module remotes

--------------------------------------------------
-- Event names and EventUIDs for events created with @{EventManager.new_event}.
--
-- Requiring this file returns a table of @{key -> value} pairs,
-- just like @{FOBJ defines.events}.
-- Because EventUIDs are dynamically generated and can change with every
-- game start, installed mod, etc.., you must use this file if you want
-- to access these EventUIDs.
--
-- __Technical Details:__
--
-- This is equivalent to @{EventManager.event_uid} but doesn't require EventManager .
--
-- Requiring this file simply calls @{Remote.PackedInterfaceGroup:get_all}
-- on the  @{Remote.PackedInterfaceGroup} named 
-- `'eradicators-library:custom-event-uids'`.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Experimental 2020-10-31.
--
-- @usage
--  defines.erlib_events
--   = require('__eradicators-library__/erlib/remotes/get_erlib_event_uids')
--
-- @within Files
-- @table remotes.get_erlib_event_uids
  
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
return elreq('erlib/factorio/Remote')()
  .PackedInterfaceGroup(UID_INTERFACE_NAME):get_all()
