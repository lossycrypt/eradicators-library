-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- (This module is not factorio compatible.)
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
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
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
if flag.IS_FACTORIO then return function()end, function()end, nil end


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Time,_Time,_uLocale = {},{},{}




----------
-- Waits until the time it up.
--
-- Uses os.clock() outside of factorio.
--
-- Inside of factorio uses a busy wait loop to __approximate__ the wait time.
-- The approximation is based on a 2.35Ghz CPU. Depending on your CPU speed
-- the actually waited time will  be off by a factor of 2-3.
--
-- __Note:__ Inside of factorio only waits if flag.IS\_DEV\_MODE is true.
--
-- @tparam int ms milliseconds.
--
-- @function Time.wait

if _ENV.os and _ENV.os.clock then

  -- Outside of factorio precise waiting is possible.
  local os_clock = os.clock
  function Time.wait(ms)
    local _end = os_clock() + (ms/1000)
    repeat until os_clock() >= _end
    end

else

  if not flag.IS_DEV_MODE then

    -- In factorio there is no good reason to waste cpu
    -- on user systems.
    function Time.wait() end

  else

    -- os.clock is not available in Factorio.
    -- So approximate waiting is the only possibility
    local cycles_per_millisecond = 200000000*0.7/1000 -- ~cpm*1000 -> 1100ms @ 2.3Ghz
    function Time.wait (ms)
      for i=1,cycles_per_millisecond * ms do end
      end

    end

  end





--------------------------------------------------------------------------------
-- Section
-- @section
--------------------------------------------------------------------------------


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Time') end
return function() return Time,_Time,_uLocale end
