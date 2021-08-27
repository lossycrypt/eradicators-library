-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description
--
-- @submodule Iter
-- @usage
--  local array_pairs = require('__eradicators-library__/erlib/lua/Iter/array_pairs')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local stop   = elreq('erlib/lua/Error')().Stopper('array_pairs')

local unpack = table.unpack

local type,pairs,ipairs = type,pairs,ipairs

local Table = elreq('erlib/lua/Table')()
local Table_array_size = Table.array_size

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --



----------
-- Iterates over dense, sparse or partial arrays.
-- Can also iterate over the array part of a @{MixedTable}.
-- Start and end point of the array are determind on calling, thus any changes
-- to the array during the iteration have no effect on the interation range.
--  
-- @tparam table|array tbl 
-- @tparam NaturalNumber i Start of the iteration range.
-- @tparam NaturalNumber j End of the iteration range.
-- @treturn function A @{next}-style iterator that returns (index,value) pairs
-- when called with (tbl,last_key).
-- 
-- @usage
--   local my_mixed_table = {'a',[42]='u',[6]='f',test='bla'}
--
--   -- By default it will find the largest key on it's own.
--   for k,v in Iter.array_pairs(my_mixed_table) do print(k,v) end
--   > 1 a
--   > 6 f
--   > 42 u
--   
--   -- You can enforce partial ranges. This *will* iterate the whole range
--   -- even if only a few keys have values. So speficying huge numbers
--   -- will just pointlessly waste CPU cycles.
--   for k,v in Iter.array_pairs(my_mixed_table,6,9001) do print(k,v) end
--   > 6 f
--   > 42 u
--
local function array_pairs(tbl, i, j)
  j = j or Table_array_size(tbl)

  -- V1
  -- local function _iter(arr,k)
  --   local v
  --   while (v == nil) and (k < j) do
  --     k = k + 1
  --     v = arr[k]
  --     end
  --   if v ~= nil then return k,v end
  --   end
    
  -- V2
  local function _iter(arr, k)
    while (k < j) do
      k = k + 1
      if arr[k] ~= nil then return k, arr[k] end
      end
    end
    
  return _iter, tbl, (i and i-1 or 0) -- iteration starts at the *next* number.
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.array_pairs') end
return function() return array_pairs, nil end
