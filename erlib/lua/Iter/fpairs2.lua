-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @submodule Iter
-- @usage
--  local fpairs2 = require('__eradicators-library__/erlib/lua/Iter/fpairs2')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

local type,pairs,next,table_unpack
    = type,pairs,next,table.unpack

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
-- local stop   = elreq('erlib/lua/Error')().Stopper('fpairs2')
local Table   = elreq('erlib/lua/Table')()

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

----------
-- Iterates the @{NotNil} return values of a filter function over a table.
--
-- @tparam table tbl
-- @tparam function f
--
-- @treturn function A __stateful__ iterator function.
-- For each call of the iterator it returns all return values
-- of the next call of `'f(value,key,tbl)'` that returns at least one value.
-- The iterator terminates after f has been called on all elemetnts of tbl.
--
local function fpairs2(tbl, f)
  assert(tbl)
  assert(f)
  local next, tbl, start = pairs(tbl) --respect custom iterator
  local k, n
  local function _iter()
    local v
    repeat 
      k, v = next(tbl, k)
      if k == nil then return nil end
      v = {f(v, k, tbl)}
      n = Table.array_size(v) --v can be sparse!
      until (n > 0)
    return table_unpack(v,1,n) end
  return _iter end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Iter.fpairs2') end
return function() return fpairs2 end
