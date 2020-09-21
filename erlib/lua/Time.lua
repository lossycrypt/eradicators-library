-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- This module is not factorio compatible.
--
-- @module Time
-- @usage
--  local Time = require('__eradicators-library__/erlib/factorio/Time')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
if flag.IS_FACTORIO then return function()end, function()end, nil end


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Time,_Time,_uLocale = {},{},{}




----------
-- Waits until the time it up.
-- @tparam int ms milliseconds.
-- @function Time.wait
  do
  local os_clock = os.clock
function Time.wait(ms)
  local _end = os_clock() + (ms/1000)
  repeat until os_clock() > _end
  end end






--------------------------------------------------------------------------------
-- Section
-- @section
--------------------------------------------------------------------------------


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Time') end
return function() return Time,_Time,_uLocale end
