-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @submodule Iter
-- @usage
--  local permutations = require('__eradicators-library__/erlib/lua/Iter/permutations')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local stop   = elreq('erlib/lua/Error')().Stopper('permutations')

local table_unpack
    = table.unpack

-- -------------------------------------------------------------------------- --
-- Local Code Copies                                                          --
-- -------------------------------------------------------------------------- --

-- Iter.permutations is required by lua.Verificate. Because Verificate is
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
  
local function Table_range(a,b,step)
  local r = {}
  for i=(b and a or 1),(b or a),(step or ((b and a>b) and -1) or 1) do
    r[#r+1]=i
    end
  return r
  end
  
    
-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --


-- -------------------------------------------------------------------------- --
-- Third-party Code                                                           --
-- -------------------------------------------------------------------------- --
  
  -- Short code, but iterator usability questionable?
  -- [1] https://rosettacode.org/wiki/Permutations#Lua
  
  -- Iterator/Generator capable algorythm.
  -- [2] https://rosettacode.org/wiki/Permutations_by_swapping#Lua
  -- [3] https://en.wikipedia.org/wiki/Steinhaus–Johnson–Trotter_algorithm#Even's_speedup

  local _SJT_mt = {
  
    largestMobile = function(self)
      for i=#self.values,1,-1 do
        local loc=self.positions[i]+self.directions[i]
        if loc >= 1 and loc <= #self.values and self.values[loc] < i then
          return i
          end
        end
      return 0
      end,
      
    next = function(self)
      local r=self:largestMobile()
      if r==0 then return false end
      local rloc=self.positions[r]
      local lloc=rloc+self.directions[r]
      local l=self.values[lloc]
      self.values[lloc],self.values[rloc] = self.values[rloc],self.values[lloc]
      self.positions[l],self.positions[r] = self.positions[r],self.positions[l]
      self.sign=-self.sign
      for i=r+1,#self.directions do self.directions[i]=-self.directions[i] end
      return true
      end,

    }

  local function SJT(dim)
    local n={ values={}, positions={}, directions={}, sign=1 }
    setmetatable(n,{__index=_SJT_mt})
    for i=1,dim do
      n.values[i]=i
      n.positions[i]=i
      n.directions[i]=-1
    end
    return n
  end

  -- Original usage example (be careful of usage before next()!):   
  --!
  -- perm=JT(4)
  -- repeat
  --   print(unpack(perm.values))
  -- until not perm:next()
    
-- -------------------------------------------------------------------------- --
  
  
----------
-- Iterates through all permutations that contain each value exactly once.
-- A permutation is a list in which only the order of elements changes.
--
-- __Time complexity:__ Factorial of size of arr → #arr!
--
-- __See also:__ @{Iter.combinations}, @{Iter.subsets}
--
-- @tparam[opt] DenseArray|SparseArray arr If not given will instead use a
-- @{Table.range}(i,j).
-- @tparam[opt=1] NaturalNumber i The index of the first value that shall be part of the permutation.
-- @tparam[opt=#arr] NaturalNumber j The index of the last value that shall be part of the permutation.
--
-- @treturn function A stateful iterator that returns an array for each
-- permutation.
--
-- @usage
--   for arr in Iter.permutations({1,2,3,4,5},1,3) do print(Hydra.line(arr)) end
--   > {1, 2, 3}
--   > {1, 3, 2}
--   > {3, 1, 2}
--   > {3, 2, 1}
--   > {2, 3, 1}
--   > {2, 1, 3}
--
local function permutations(arr,i,j)
  --@future: This gotta be possible with a less complicated algorythm!

  -- Partial Array
  i,j = (i or 1), (j or Table_array_size(arr))
  local length = j-i+1
  if length <= 0 then return function()end end
  
  if not arr then
    arr = Table_range(i,j)
    i,j = 1,length
    end
  
  -- Permutation Generator + Getter
  local _gen = SJT(length)
  local function get()
    local r = {}
    for k=1,length do r[k] = arr[ _gen.values[k] + i - 1 ] end
    return r
    end

  -- The first valid permutation is *before* _get:next().
  local rest  = function () if _gen:next() then return get() end end
  local _f;_f = function () _f = rest           return get() end
  local _iter = function () return _f() end

  return _iter
  end

  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.permutations') end
return function() return permutations,_permutations,_uLocale end
