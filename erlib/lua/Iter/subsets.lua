-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @submodule Iter
-- @usage
--  local subsets = require('__eradicators-library__/erlib/lua/Iter/subsets')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local stop   = elreq('erlib/lua/Error')().Stopper('subsets')

local type
    = type

local table_unpack, math_floor
    = table.unpack, math.floor


-- -------------------------------------------------------------------------- --
-- Local Code Copies                                                          --
-- -------------------------------------------------------------------------- --

-- Iter.subsets is required by lua.Verificate. Because Verificate is
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
-- Produces all possible unique subsets of size n from a given superset arr.
-- This means that it is guaranteed that for each possible combination of
-- unique elements exactly one permutation will occur.
--
-- __Time complexity:__ It depends \*cough\*.
--
-- __Note:__ Despite the name sub-"set" all in- and outputs use array format for
-- better performance.
--
-- __See also:__ @{Iter.combinations}, @{Iter.permutations}
--
-- @tparam NaturalNumber size The exact size of each subset.
-- @tparam array arr An array representing all elements of the source set.
--
-- @treturn function A stateful iterator that returns an array for each
-- subset.
--
-- @usage
--   -- A set with n elements only has one subset of length n.
--   for s in Iter.subsets(3,{1,2,3}) do print(Hydra.line(s)) end
--   > {1, 2, 3}
--
-- @usage
--   for s in Iter.subsets(3,{1,2,3,4,5}) do print(Hydra.line(s)) end
--   > {1, 2, 3}
--   > {1, 2, 4}
--   > {1, 2, 5}
--   > {1, 3, 4}
--   > {1, 3, 5}
--   > {1, 4, 5}
--   > {2, 3, 4}
--   > {2, 3, 5}
--   > {2, 4, 5}
--   > {3, 4, 5}
--
local function subsets(size,arr)
  -- Algorythmus startet mit einer "Treppe" deren Stufen Schritt für Schritt von
  -- Hinten erhöht werden solange alle Stufen unterschiedlich "hoch" sind. Wenn
  -- eine Stufe ihren lokalen Maximalwert erreicht hat werden sie und alle
  -- ihr folgenden Stufen auf ihren jetzigen Minimalwert heruntergesetzt.
  
  -- Maximum possible key
  local max = Table_array_size(arr)
  
  -- Tautologically no subset of that size exists.
  if max  < size then return function()end end
  if size < 1    then return function()end end

  -- Start with a Treppe 1,2,3,..,n
  local keys = {}; for i=1,size do keys[i] = i end
  -- first loop requires minus one offset
  keys[size] = size - 1
  
  local function get()
    local r = {}
    for i=1,size do r[i] = arr[ keys[i] ] end
    return r
    end

  local function _iter()
    local pos = size
    while true do
      keys[pos] = keys[pos] + 1
      -- in einer Treppe hat jede Stufe einen anderen Maximalwert
      if (keys[pos] > (max-(size-pos))) then
        if pos == 1 then return nil end -- end of loop
        local offset = keys[pos-1] - (pos-1) + 1
        for i=pos,size do keys[i] = i + offset end -- reset this and following
        pos = pos - 1 -- prev will be incremented at start of next loop
      else
        return get()
        end
      end
    end
  
  return _iter
  end


  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.subsets') end
return function() return subsets,_subsets,_uLocale end
