-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @module EventManager
-- @usage
--  local EventManager = require('__eradicators-library__/erlib/factorio/EventManager')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local EventManager,_EventManager,_uLocale = {},{},{}


--------------------------------------------------------------------------------
-- Section
-- @section
--------------------------------------------------------------------------------

  ----------
  -- Redirects standard script calls to erlib.EventManager for easy
  -- multi-handler events without rewriting the mod.
  EventManager.InterceptLuaBootstrap = function()
    --Can not do this in core because it requires EventManager access!?
    --Also the EM kinda needs to do this by default anyway to be usable
    --at all in i.e. /sudo etc. Otherwise script.on_event calls would 
    --completely break it.
    local _real_script = _ENV.script
    local _CoreScript = {}
    _ENV.script = setmetatable(_CoreScript,{__index=_real_script})

    function _CoreScript.on_event(id,func)
      -- EventManager redirect
      end

    end

----------
-- Nothing.
-- @within Todo
-- @field todo1

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.EventManager') end
return function() return EventManager,_EventManager,_uLocale end
