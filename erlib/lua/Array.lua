-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Numerically indexed table manipulation.
-- Supports 0-indexed arrays?
-- Everything works for sparse arrays?
-- -> The point of this whole module is to be *fast*. 
--    So any slow operations like MixedTable2Array should be in Table!
-- 
-- @module Array
-- @usage
--  local Array = require('__eradicators-library__/erlib/lua/Array')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local Table,_Table = elreq('erlib/lua/Table')()

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Array,_Array,_uLocale = {},{},{}

-- -------------------------------------------------------------------------- --
-- Metatable                                                                  --
-- -------------------------------------------------------------------------- --

-- Inherit all Table methods.
for k,v in pairs( Table) do  Array[k] = v end
for k,v in pairs(_Table) do _Array[k] = v end

local _toArray = function(  tbl) return setmetatable(tbl,Array) end
Array.__call   = function(_,tbl) return setmetatable(tbl,Array) end
Array.__index = Array
do setmetatable(Array,Array) end

--------------------------------------------------------------------------------
-- SparseArray
-- @section
--------------------------------------------------------------------------------


----------
-- The size of this array. For non-spares @{array}s it's faster to use #.
-- @tparam SparseArray arr
-- @treturn NaturalNumber 
function Array.size(arr)
  local last = -1
  for i in pairs(arr) do
    if i > last then last = i end
    end
  return (last ~= -1) and last or nil
  end

local Array_size = Array.size


----------
-- __In-place.__ Compresses a @{SparseArray} into a @{DenseArray}. The order of the elements
-- is preserved. Can also compress only parts of the input, for example to
-- split the compression into multiple steps.
-- @tparam SparseArray arr
-- @tparam[opt=1] NaturalNumber i Partial array start index.
-- @tparam[opt=Array.size(arr)] NaturalNumber j Partial array end index.
-- @treturn DenseArray
function Array.compress(arr,i,j)
  local n = i
  for k=(i or 1),(j or Array.size(arr)) do
    local v = arr[k]
    if v ~= nil then
      arr[k] = nil
      arr[n] = v
      n = n + 1
      end
    end
  return _toArray(arr)
  end

--------------------------------------------------------------------------------
-- DenseArray.
-- @section
--------------------------------------------------------------------------------


----------
-- __In-place.__ Applies a function to all elements of an array.
-- 
-- @tparam Array arr
-- @tparam function f The function f(value,index,arr) that is applied to every
-- key→value mapping in the array. If __f() returns nil__ for any value then
-- the __return__ array will be __sparse__.
--
-- @tparam NaturalNumber i The index at which to start the operation.
-- @tparam NaturalNumber j The index at which to end the operation.
--
-- @treturn DenseArray|SparseArray
function Array.map(arr,f,i,j)
  for k=(i or 1),(j or #arr) do
    arr[k] = f(arr[k],k,arr)
    end
  return _toArray(arr)
  end


-- Array(tbl):scopy():map(f):compress()
  


-- @todo: sparse_ipairs() --iterate the sparese array part of a mixed table

--------------------------------------------------------------------------------
-- Section
-- @section
--------------------------------------------------------------------------------

----------
-- Nothing.
-- @within Todo
-- @field todo1

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Array') end
return function() return Array,_Array,_uLocale end
