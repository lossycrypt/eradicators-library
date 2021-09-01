-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
-- -------------------------------------------------------------------------- --
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local log         = elreq('erlib/lua/Log'          )().Logger  'babelfish'

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Local = {}

-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --

-- Creates an auto-resetting profiler or a dummy function.
function Local.get_profiler()
  return (not flag.IS_DEV_MODE) and ercfg.SKIP or (function(profiler)
    return function(msg) log:profilerf(profiler, msg); profiler.restart() end
    end)(game.create_profiler())
  end

-- ticks per second
function Local.ticks_per_second_float() return            60 * game.speed  end
function Local.ticks_per_second_int  () return math.floor(60 * game.speed) end
  
return Local