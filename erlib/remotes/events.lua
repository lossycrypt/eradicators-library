-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- @module remotes

--------------------------------------------------
-- Event names shared amongst all Erlib using mods.
--
-- This file exists for mods that want to use Erlib's event id sharing
-- mechanism __without__ using @{EventManagerLite}. Just require this
-- file and call the returned function.
--
-- @usage
--  local events, generate_event_name
--    = require('__eradicators-library__/erlib/remotes/events')()
--
-- @treturn table Stand-alone version of @{EventManagerLite.events}.
-- @treturn function Stand-alone version of @{EventManagerLite.generate_event_name}.
--
-- @within Files
-- @function remotes.events
  
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
-- local log         = elreq('erlib/lua/Log'       )().Logger  'remotes.events'
local stop        = elreq('erlib/lua/Error'     )().Stopper 'remotes.events'
local assertify   = elreq('erlib/lua/Error'     )().Asserter(stop)

local Verificate  = elreq('erlib/lua/Verificate')()
local verify      = Verificate.verify

local Remote      = elreq('erlib/factorio/Remote')()

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --

-- Verify that EML isn't loaded and ensure we
-- have access to native LuaBootstrap.
local script = assert(_ENV.script)
local msg = 'remotes/events is redundant when using EventManagerLite'
assert(script.object_name ~= 'ManagedLuaBootstrap', msg)
assert(script.object_name == 'LuaBootstrap'       , msg)

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local EventPIG = Remote.PackedInterfaceGroup('erlib:managed-events')

-- Wrapper table that contains no keys itself.
-- (EventPIG does contain several internal data keys).
local events = setmetatable({}, {
  __index = function(self, name)
    return assertify(EventPIG:get(name), 'Unknown event name: ', name)
    end,
  __newindex = function(self, name, id)
    verify(id, 'NaturalNumber', 'Invalid event id: ', id)
    EventPIG:set(name, id)
    end,
  __pairs = function()
    return pairs(EventPIG)
    end,
    })

local generate_event_name = function(name)
    if name == nil then return script.generate_event_name() end
    verify(name, 'string', 'Invalid event name.')
    return EventPIG:get(name)
        or EventPIG:set(name, script.generate_event_name())
    end

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
return function(caller)
  if caller == 'EventManagerLite' then
    return events, generate_event_name, EventPIG -- internal use only!
  else
    return events, generate_event_name
    end
  end