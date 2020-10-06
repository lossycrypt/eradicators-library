-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @submodule Iter
-- @usage
--  local combinations = require('__eradicators-library__/erlib/lua/Iter/combinations')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local stop   = elreq('erlib/lua/Error')().Stopper('combinations')

local type
    = type

local table_unpack, math_floor
    = table.unpack, math.floor


-- -------------------------------------------------------------------------- --
-- Local Code Copies                                                          --
-- -------------------------------------------------------------------------- --

-- Iter.combinations is required by lua.Verificate. Because Verificate is
-- a bootstrap module it can not use anything that itself has other dependencies.

-- local Table = elreq('erlib/lua/Table')()

local function Table_array_size(tbl)
  local last = 0
  for i in pairs(tbl) do
    if type(i) == 'number'
    and i % 1 == 0
    and i > last then
      last = i
      end
    end
  return last
  end

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

----------
-- Iterates over all n-length combinations of the given values.
-- Each value can be in the combination multiple times.
--
-- __Time complexity:__ Size of arr to the power of length → #arr ^ length
--
-- __See also:__ @{Iter.subsets}, @{Iter.permutations}
--
-- @tparam NaturalNumber length The exact length of every combination.
-- @tparam DenseArray|SparseArray arr The values to be combined.
--
-- @treturn function A stateful iterator that returns an array for each
-- combination.
--
-- @usage
--   for arr in Iter.combinations(3,{0,1}) do print(Hydra.line(arr)) end
--   > {0, 0, 0}
--   > {0, 0, 1}
--   > {0, 1, 0}
--   > {0, 1, 1}
--   > {1, 0, 0}
--   > {1, 0, 1}
--   > {1, 1, 0}
--   > {1, 1, 1}
--
local function combinations(length,arr)
  -- Iterates over an index counter of the form {k,k,k,k,k} that
  -- represents keys in the given array. Kinda like an electricity counter.

  -- n is the number of combinable elements.
  local n = Table_array_size(arr)
  
  -- prefill the index array with 1's
  local keys = {}; for i=1,length do keys[i]=1 end
  
  -- first round of _iter needs a -1 offset to catch the first combination.
  keys[length] = 0
  
  local function _iter()
    -- Every iteration starts with incrementing the last index. If by
    -- that the index becomes too large then _iter walks backwards towards the
    -- first index until an index can be safely incremented
    -- or all indexes have been exhausted.
    
    local pos = length
    
    while pos > 0 do
      keys[pos] = keys[pos] + 1
      if keys[pos] > n then keys[pos], pos = 1, pos - 1 else break end
      end
   
    if pos > 0 then
      -- The return value has to be a table to allow combinations containing
      -- nil. Otherwise the for loop would terminate when a nil value is
      -- returned in the first position.
      local r = {}
      for i=1,length do r[i] = arr[ keys[i] ] end
      return r
      -- return {table_unpack(r,1,length)}
      end
    end
  
  return _iter
  end
  
  
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.combinations') end
return function() return combinations,_combinations,_uLocale end
