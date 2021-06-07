-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Inline replication of object references.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Polishing.
--
-- @module Replicate
-- @usage
--  local Replicate = require('__eradicators-library__/erlib/lua/Replicate')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Replicate,_Replicate,_uLocale = {},{},{}


----------
-- Returns two references to the given object.
-- @tparam AnyValue v
-- @usage local A,B = Twice(f)
Replicate.Twice  = function(v) return v,v   end


----------
-- Returns three references to the given object.
-- @tparam AnyValue v
-- @usage local A,B,C = Thrice({})
Replicate.Thrice = function(v) return v,v,v end


----------
-- Returns 42 references to the given object.
-- That should be enough for everyone.
-- @tparam AnyValue v
-- @usage local A,B,C,D,E,F,G = FourtyTwo(LuaEntity) --You don't have to catch 'em all.
Replicate.FourtyTwo = function(v)
  return v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v,v
  end

----------
-- Returns n references to the given object.
-- For when you need precision.
-- @tparam NaturalNumber n
-- @tparam AnyValue v
-- @usage local A,B,C,E,F,G = Replicate(6,LuaEntity)
Replicate.Replicate = function(n,v)
  -- V1
  local r = {}; for i=1,n do r[#r+1] = v end
  return unpack(r)
  end

-- 2020-10-31, works, but is it worth requiring two additional modules?
-- do 
--   -- V2, memoized Lambda with [0]
--   local fn = Memoize(function(n) return L['_->_' .. (',_'):rep(n-1)] end)
--   fn[0] = ercfg.SKIP
-- function Replicate.Replicate (n,v)
--   return fn[n](v)
--   end
--   end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Replicate') end
return function() return Replicate,_Replicate,_uLocale end
