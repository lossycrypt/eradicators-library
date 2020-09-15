-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Inline replication of object references.
--
-- @module Multiplex
-- @usage
--  local Multiplex = require('__eradicators-library__/erlib/lua/Multiplex')()
  
  

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Multiplex,_Multiplex,_uLocale = {},{},{}


----------
-- Returns two references to the given object.
-- @tparam AnyValue v
-- @usage local A,B = Duplex(f)
Multiplex.Duplex  = function(v) return v,v   end


----------
-- Returns three references to the given object.
-- @tparam AnyValue v
-- @usage local A,B,C = Triplex({})
Multiplex.Triplex = function(v) return v,v,v end

----------
-- Returns n references to the given object.
-- @tparam NaturalNumber n
-- @tparam AnyValue v
-- @usage local A,B,C,E,F,G = Multiplex(6,LuaEntity)
Multiplex.Multiplex = function(n,v)
  local r = {}; for i=1,n do r[#r+1] = v end
  return unpack(r)
  -- @future use memoized lambda sub-function for speed?
  -- local f = Memoize.one_arg(function(n) return L('_1'..string.rep(',_1',n)) end)
  -- return f(n)(v)
  end

  
  

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
return function() return Multiplex,_Multiplex,_uLocale end
