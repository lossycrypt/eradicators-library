-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- N-Argument logic operators.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Experimental 2020-10-31.
--
-- @module Logic
-- @usage
--  local Logic = require('__eradicators-library__/erlib/factorio/Logic')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local select = select

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Logic,_Logic,_uLocale = {},{},{}

--------------------------------------------------------------------------------
-- Basic
-- @section
--------------------------------------------------------------------------------


----------
-- And-compares an arbitrary number of objects for __truthyness__.
-- @treturn boolean True if __all__ objects were truthy.
function Logic.And(...) return not not Logic.Andy(...) end

----------
-- Or-compares an arbitrary number of objects for __truthyness__.
-- @treturn boolean True if __at least one__ object was truthy.
function Logic.Or (...) return not not Logic.Ory (...) end

----------
-- Exclusive-Or-compares an arbitrary number of objects for __truthyness__.
-- @treturn boolean True if __exactly one__ object was truthy.
function Logic.Xor(...) return not not Logic.Xory(...) end



--------------------------------------------------------------------------------
-- Advanced.
-- Advanced functions return one of the objects instead of @{boolean}.
-- @section
--------------------------------------------------------------------------------
  
----------
-- And-compares an arbitrary number of objects for __truthyness__.
-- @tparam AnyValue ...
-- @treturn AnyValue|false The __last__ truthy object if `Logic.And(...)`
-- would've been true.
function Logic.Andy (...)
  local r,args,n = true,{...},select('#',...)
  for i=1,n do
    r = r and args[i]
    if not r then break end -- already false
    end
  return r or false
  end
  
----------
-- Or-compares an arbitrary number of objects for __truthyness__.
-- 
-- @tparam AnyValue|false ...
-- @treturn AnyValue The __first__ truthy object if `Logic.Or(...)` would've been true.
function Logic.Ory (...)
  local r,args,n = false,{...},select('#',...)
  for i=1,n do
    r = r or args[i]
    if r then break end -- already true
    end
  return r or false
  end


----------
-- Exclusive-Or-compares two objects for __truthyness__.
-- @tparam AnyValue ...
-- @treturn AnyValue|false The __only__ truthy object if `Logic.Xor(...)`
-- would've been true.
function Logic.Xory (...)
  -- V1: return (not a and b) or (a and not b)
  local r,args,n = false,{...},select('#',...)
  for i=1,n do
    if r and args[i] then
      return false
    else
      r = r or args[i]
      end
    end
  return r or false -- convert possible <nil> value
  end
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Logic') end
return function() return Logic,_Logic,_uLocale end
