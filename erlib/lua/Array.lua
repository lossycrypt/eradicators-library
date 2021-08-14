-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Numerically indexed table manipulation. Optimized for speed.
-- 
-- __Note:__ All methods of this module that return an array also set the
-- metatable of the result to this module, except for in-place methods that
-- recieve an input that already had a metatable.
--
-- __Note:__ Some methods of this module apply their result directly to the 
-- input table to be faster. If you want the input table to be unaffected you
-- can supply an (empty) table as the _target_ to which the result should
-- be written instead. This allows both in-place and copy-on-write operations
-- to be handled by the same method at the same cpu-cost.
--
-- __Note:__ This module inherits all @{Table} module methods. Same-named
-- Array methods override inherited Table methods.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Polishing.
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
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local Table,_Table = elreq('erlib/lua/Table')()

local setmetatable, getmetatable, pairs
    = setmetatable, getmetatable, pairs

local math_floor, math_ceil, table_sort, table_unpack, table_remove
    = math.floor, math.ceil, table.sort, table.unpack, table.remove

local stop = elreq('erlib/lua/Error')().Stopper('Array')

local Table_size
    = Table.size
    
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


local _obj_mt = {__index=Array}
-- attach meta if safe
local _toArray = function(tbl)
  if not getmetatable(tbl) then setmetatable(tbl,_obj_mt) end
  return tbl end
-- user request to attach meta unconditionally
do setmetatable( Array,{__call = function(_,tbl) return setmetatable(tbl,_obj_mt) end}) end
do setmetatable(_Array,{__call = function(_,tbl) return setmetatable(tbl,_obj_mt) end}) end


--------------------------------------------------------------------------------
-- Module.
-- @section
--------------------------------------------------------------------------------

-- -------
-- Nothing.
-- @within Todo
-- @field todo1



----------
-- Attaches the Array modules metatable to any table.
-- @tparam table arr
-- @treturn DenseArray|SparseArray|MixedTable The unchanged input table.
-- @function Array
do end


--------------------------------------------------------------------------------
-- Basic Methods.
-- @section
--------------------------------------------------------------------------------

----------
-- The size of this array.  
-- For @{DenseArray}s 
-- @{The Length Operator|the length operator #} is __much faster__.  
-- For @{MixedTable}s you have to use @{Table.array_size} instead.
--
-- @tparam SparseArray arr
--
-- @treturn NaturalNumber
--
function Array.size(arr)
  local last = 0
  for i in pairs(arr) do
    if i > last then last = i end
    end
  return last
  end
  
  
----------
-- Produces an array of only the keys with @{NotNil} values of this array.
-- Values are not preserved.
--  
-- @tparam DenseArray|SparseArray arr
--  
-- @tparam[opt=1]    NaturalNumber i First index to process. Mandatory for sparse input.
-- @tparam[opt=#arr] NaturalNumber j Last index to process. Mandatory for sparse input.
--
-- @treturn DenseArray
--
function Array.keys(arr,i,j)
  local r = {}
  for k=(i or 1),(j or #arr) do
    if arr[k] ~= nil then r[#r+1] = k end
    end
  return _toArray(r)
  end
  
  
----------
-- Produces an array of only the @{NotNil} values of this array. Keys are not preserved.
--  
-- @tparam DenseArray|SparseArray arr
--  
-- @tparam[opt=1]    NaturalNumber i First index to process. Mandatory for sparse input.
-- @tparam[opt=#arr] NaturalNumber j Last index to process. Mandatory for sparse input.
--
-- @treturn DenseArray
--
function Array.values(arr,i,j)
  local r = {}
  for k=(i or 1),(j or #arr) do
    if arr[k] ~= nil then r[#r+1] = arr[k] end
    end
  return _toArray(r)
  end


  
--------------------------------------------------------------------------------
-- Search Methods.
-- @section
--------------------------------------------------------------------------------

----------
-- Finds the first nil value in an array.
-- For DenseArrays this is equivalent to #arr+1.
--
-- @tparam SparseArray arr
--
-- @tparam[opt=1]    NaturalNumber i First index to process.
-- @tparam[opt=infinity] NaturalNumber j Last index to process.
--
-- @treturn NaturalNumber|nil The first index >= i, that has the
-- value @{nil}. Or nil if a fixed range i,j was given and there
-- were no nil values in that range. Or nil if array size exeeds
-- @{wiki IEEE754} double-precision floating-point range (2^53).
--
-- @function Array.first_gap
  do
  -- Numbers outside of IEEE754 double-precision floating point
  -- range are not reliable array keys.
  local double_float_max = 2^53
function Array.first_gap(arr,i,j)
  local k = (i or 1)
  local j = (j or double_float_max)
  while arr[k] and k < j do k = k + 1 end
  if arr[k] == nil then --j limit might not be a gap
    return k
    end
  end
  end


----------
-- Finds the first occurance of a value in an array.
--
-- @tparam DenseArray|SparseArray arr
-- @tparam NotNil value
--
-- @tparam[opt=1]    NaturalNumber i First index to process. Mandatory for sparse input.
-- @tparam[opt=#arr] NaturalNumber j Last index to process. Mandatory for sparse input.
--
-- @treturn NaturalNumber|nil The index of the __first occurance__ of the value
-- in the range i,j, or nil if value wasn't found.
--
function Array.find(arr,value,i,j)
  for k=(i or 1),(j or #arr) do
    if arr[k] == value then return k end
    end
  end
  

----------
-- Finds all occurances of a value in an array.
--
-- @tparam DenseArray|SparseArray arr
-- @tparam NotNil value
--
-- @tparam[opt=1]    NaturalNumber i First index to process. Mandatory for sparse input.
-- @tparam[opt=#arr] NaturalNumber j Last index to process. Mandatory for sparse input.
--
-- @treturn DenseArray A list of keys in arr that have the value. Can be empty.
--
function Array.find_all(arr,value,i,j)
  local r = {}
  for k=(i or 1),(j or #arr) do
    if arr[k] == value then r[#r+1]= k end
    end
  return _toArray(r)
  end
  

  
--------------------------------------------------------------------------------
-- In-Place Methods.
-- @section
--------------------------------------------------------------------------------
  
----------
-- __In-place.__ Compresses a @{SparseArray} into a @{DenseArray}. The order of
-- the elements is preserved. Can also compress partial ranges of the input,
-- for example to split the compression into multiple steps.
--
-- __Note:__ If you know the size of the array then giving it as j significantly
-- improves performance.
--
-- __Note:__ To compress @{MixedTable}s you can give Table.array_size(arr) as j.
--
-- @tparam SparseArray arr
-- @tparam[opt=nil] table target __Copy Mode.__ This table will be changed and arr remains unchanged.
--
-- @tparam[opt=1]    NaturalNumber i First index to process. Mandatory for sparse input.
-- @tparam[opt=Array.size(arr)] NaturalNumber j Last index to process. Mandatory for sparse input.
--
-- @treturn DenseArray
--
function Array.compress(arr,target,i,j)
  target = target or arr
  local n = (i or 1)
  for k=n,(j or Array.size(arr)) do
    local v = arr[k]
    if v ~= nil then
      target[k] = nil
      target[n] = v
      n = n + 1
      end
    end
  return _toArray(target)
  end


----------
-- __In-place.__ Applies a function to all elements of an array. This function
-- __does not change__ the @{key -> value} relationship. Thus if the input array or
-- partial range includes nil values, or f() returns nil values then the output
-- will be sparse.
-- 
-- __Note:__ Due to the inherit overhead of one extra function call per element
-- performance impact should be carefully considered before using this to
-- replace normal for-ipairs loops.
--
-- __Experts only:__ Copy mode supports key reassignment like @{Table.map}.
-- 
-- @tparam DenseArray|SparseArray arr
-- @tparam function f The function f(value,index,arr) that is applied to every
-- key→value mapping in the array.
-- @tparam[opt=nil] table target __Copy Mode.__ This table will be changed and
-- arr remains unchanged.
--
-- @tparam[opt=1]    NaturalNumber i First index to process. Mandatory for sparse input.
-- @tparam[opt=#arr] NaturalNumber j Last index to process. Mandatory for sparse input.
--
-- @treturn DenseArray|SparseArray
function Array.map(arr,f,target,i,j)
  -- in-place
  if not target then
    for k=(i or 1),(j or #arr) do
      arr[k] = f(arr[k],k,arr)
      end
    return _toArray(arr)
  -- copy
  else
    for k=(i or 1), (j or #arr) do
      local v2, k2 = f(arr[k], k, arr)
      if k2 == nil then
        target[k ] = v2
      else
        target[k2] = v2
        end
      end
    return _toArray(target)
    end
  end

-- V1 archived 2020-10-30
--
-- function Array.map_1(arr,f,target,i,j)
--   target = target or arr
--   for k=(i or 1),(j or #arr) do
--     target[k] = f(arr[k],k,arr)
--     end
--   return _toArray(target)
--   end

  
 
----------
-- __In-place.__ Removes elements from an array based on a filter function.
--
-- __Note:__ Due to the inherit extra overhead of one function call per element
-- this will always be slower than a simple for-pairs loop.
--
-- @tparam DenseArray|SparseArray arr
-- @tparam function f Any elements for which the filter function f(value,index,arr)
-- does not return @{truthy} are removed from the array. And any
-- following indexes are shifted down.
-- @tparam[opt=nil] table target __Copy Mode.__ This table will be changed and arr remains unchanged.
--
-- @tparam[opt=1]    NaturalNumber i First index to process. Mandatory for sparse input.
-- @tparam[opt=#arr] NaturalNumber j Last index to process. Mandatory for sparse input.
--
-- @treturn DenseArray Indexes will be shifted down if values have been deleted.
--
function Array.filter(arr,f,target,i,j)
  target = target or arr
  local n = (i or 1)
  for k=n,(j or #arr) do
    if f(arr[k],k,arr) then
      target[n],target[k] = arr[k],nil
      n = n + 1
    else
      target[k] = nil
      end
    end
  return _toArray(target)
  end

  
----------
-- __In-place.__ Reverses the order of an array.
--
-- @tparam DenseArray|SparseArray arr
-- @tparam[opt=nil] table target __Copy Mode.__ This table will be changed and arr remains unchanged.
--
-- @tparam[opt=1]    NaturalNumber i First index to process. Mandatory for sparse input.
-- @tparam[opt=#arr] NaturalNumber j Last index to process. Mandatory for sparse input.
-- 
-- @treturn DenseArray|SparseArray
-- 
function Array.reverse(arr,target,i,j)
  target = target or arr
  i,j = (i or 1), (j or #arr)
  local n = j
  --must include center for odd lengths to include center in target
  for k=i,i+math_floor((j-i)/2) do
    target[k],target[n] = arr[n],arr[k]
    n = n-1
    end
  return _toArray(target)
  end
  

----------
-- __In-place.__ Removes redundant and nil values. Order of elements is unaffected.
-- 
-- @tparam DenseArray|SparseArray arr
-- @tparam[opt=nil] table target __Copy Mode.__ This table will be changed and arr remains unchanged.
--
-- @tparam[opt=1]    NaturalNumber i First index to process. Mandatory for sparse input.
-- @tparam[opt=#arr] NaturalNumber j Last index to process. Mandatory for sparse input.
-- 
-- @treturn DenseArray|SparseArray Can only become sparse if `j` was given and
-- was smaller than the largest array key. In copy mode if `i` was given
-- all indexes will be shifted down by `i-1` so that the array always starts at 1.
-- 
function Array.deduplicate(arr, target, i, j)
  -- (no test yet)
  i, j = (i or 1), (j or #arr)
  local n = target and 1 or i
  target = target or arr
  local seen = {}
  for k = i, j do
    local v = arr[k]
    target[k] = nil
    if (v ~= nil) and not seen[v] then
      seen  [v] = true
      target[n] = v
      n = n + 1
      end
    end
  return target end
  
  
----------
-- __In-place.__ Appends a value at the end of an array __only if__ no other
-- key in the array has an == equal value.
--
-- @tparam DenseArray arr
-- @tparam AnyValue value
-- 
-- @tparam[opt=1] NaturalNumber i Index to start searching at. Always searches
-- to the end of the array.
-- 
-- @treturn DenseArray The input array.
-- @treturn boolean false: element was already in array, true: element was
-- inserted at the end.
-- 
function Array.insert_once(arr,value,i)
  -- This function does not support i,j ranges because there
  -- is no obvious correct place to insert the value inside a range.
  -- Therefore the user should use Array.find() and handle that themselfs.
  for k=(i or 1),#arr do
    if arr[k] == value then return _toArray(arr),false end
    end
  -- The position is also fixed because if the user knew the position they
  -- could just check themselfs. Also it'd be ambigious if insert should
  -- overwrite or shift all later keys up in that case.
  arr[#arr+1] = value
  return _toArray(arr),true
  end


----------
-- __In-place.__ Puts one array into the middle of another.
-- 
-- @tparam DenseArray arr The array to insert into.
-- @tparam DenseArray arr2 The array to be inserted.
-- @tparam NaturalNumber i The index at which to start inserting arr2.
-- All values after i (inclusive) will be shifted backwards by the length of arr2.
--
-- @tparam[opt=nil] table target __Copy Mode.__ This table will be changed and arr remains unchanged.
--
-- @treturn DenseArray The array containing the merged result.
--
function Array.insert_array(arr,arr2,i,target)
  local n1, n2, i = #arr, #arr2, i-1
  if target then for k = 1, i do target[k] = arr[k] end end -- copy beginning to target
  target = target or arr
  for k = n1, i+1, -1 do target[k + n2] = arr [k] end -- shift old data back
  for k = 1 , n2      do target[i + k ] = arr2[k] end -- insert new data
  return _toArray(target)
  end
  

----------
-- __In-place.__ Replaces all instances of value with the then-last value of the array.
-- For large arrays this is __much faster__ than @{table.remove}
-- but does not preserver element order.
-- 
-- @tparam DenseArray arr
-- @tparam AnyValue value
-- 
-- @tparam[opt=1] NaturalNumber i Index to start searching at. Always searches
-- to the end of the array.
-- 
-- @treturn DenseArray The input array.
-- @treturn NaturalNumber How often the value was removed.
-- 
function Array.unsorted_remove_value(arr,value,i)
  local count = 0
  for k=#arr,(i or 1),-1 do -- reverse order to catch arr[#arr] == value
    if arr[k] == value then
      local n = #arr
      count = count + 1
      arr[n],arr[k] = nil,arr[n] -- order is important to delete k==n
      end
    end
  -- return _toArray(arr), count
  return arr, count
  end
  
  
----------
-- __Deprecated__.
function Array.unsorted_remove_key()
  -- Deprecated 2021-06-02. Future: Remove after a month or so.
  stop('Array.unsorted_remove_key is deprecated. Use Array.shuffle_pop instead.')
  end

----------
-- __In-place.__ Moves the value at index #arr to index i.
-- For large arrays this is __much faster__ than @{table.remove}
-- but does not preserve value order.
--
-- __Note:__ When i is out-of-bounds then the array remains unchanged.
-- Unlike @{table.remove} no error is raised. This is to allow easy
-- key existance checking.
--
-- @tparam DenseArray arr
-- @tparam Integer i The index to remove.
--
-- @treturn NotNil|nil The value that _was_ at `arr[i]`
--
function Array.shuffle_pop(arr, i)
  local n, v = #arr, arr[i]
  if v ~= nil then -- i.e.: local v = assert(shuffle_pop(arr,i), 'Custom error.')
    arr[n], arr[i] = nil, arr[n] -- order is important to delete i==n
    end
  return v end

----------
-- __In-place.__ Sets all values to nil. Useful if you need to keep the table
-- reference intact.
--
-- @tparam DenseArray|SparseArray arr
--  
-- @tparam[opt=1]    NaturalNumber i First index to process. Mandatory for sparse input.
-- @tparam[opt=#arr] NaturalNumber j Last index to process. Mandatory for sparse input.
--
-- @treturn EmptyArray|DenseArray|SparseArray The input array.
--
function Array.clear(arr,i,j)
  for k=(i or 1),(j or #arr) do
    arr[k] = nil
    end
  return _toArray(arr)
  end
  
  
----------
-- __In-place.__ Inserts the content of arr2 at the end of arr.
--
-- @tparam DenseArray|SparseArray arr The array that will be extended.
-- @tparam DenseArray|SparseArray arr2 The array from which to shallow-copy the new content.
--  
-- @tparam[opt=1]    NaturalNumber i First index of arr2 to process. Mandatory for sparse input.
-- @tparam[opt=#arr2] NaturalNumber j Last index of arr2 to process. Mandatory for sparse input.
--
-- @treturn DenseArray|SparseArray The input array.
--
function Array.extend(arr,arr2,i,j)
  local n = #arr-(i or 1)+1
  for k=(i or 1),(j or #arr2) do
    arr[n+k] = arr2[k]
    end
  return _toArray(arr)
  end
  
  
----------
-- __In-place.__ Applies a sorting function to an array.
-- See the @{Compare} module for built-in comparing functions.
--
-- @tparam DenseArray arr
-- @tparam function comparator A function f(a,b)→boolean which determines
-- the final order.
-- 
-- @treturn DenseArray
-- 
function Array.sort(arr,comparator)
  if not comparator then err('Missing sorting function') end
  table_sort(arr,comparator)
  return _toArray(arr)
  end
  

  
--------------------------------------------------------------------------------
-- Copy Methods.
-- @section
--------------------------------------------------------------------------------


----------
-- __Shallow Copy.__ Copies (parts of) an array to a new table. Sub-tables
-- will reference the original tables.
--
-- __Note:__ This is a speed optimized array-only variant of @{Table.scopy}.
--
-- @tparam DenseArray|SparseArray arr
--
-- @tparam[opt=1]    NaturalNumber i First index to process. Mandatory for sparse input.
-- @tparam[opt=#arr] NaturalNumber j Last index to process. Mandatory for sparse input.
--
-- @treturn DenseArray|SparseArray Indexes will be exactly as in the input.
-- Even for partial copies.
--
function Array.scopy(arr,i,j)
  i,j = (i or 1), (j or #arr)
  return _toArray { table_unpack(arr,i,j) } -- 120% faster than for-i-loop
  end

-- V1
-- function Array.scopy(arr,i,j)
--   local r = {}
--   for k=(i or 1),(j or #arr) do
--     r[k] = arr[k]
--     end
--   return _toArray(r)
--   end
  
  
  
--------------------------------------------------------------------------------
-- Other Methods.
-- @section
--------------------------------------------------------------------------------

  
----------
-- Takes elements from multiple input tables and puts them
-- into a flat array.
-- 
-- @tparam DenseArray arr
-- @tparam[opt] AnyValue ... Not giving any extra inputs is equivalent to
-- @{Array.scopy}(arr). If a table is given its values will be taken from
-- the same key as the preceeding value of arr. If a non-table is given
-- it will simply be repeated.
-- 
-- @treturn DenseArray|SparseArray
-- 
-- @usage
--   local spliced_array = Array.splice({1,2,3},42,{'a','b','c'},nil,'end')
--   print(spliced_array:to_string())
--   > {1, 42, "a", nil, "end", 2, 42, "b", nil, "end", 3, 42, "c", nil, "end"}
--
function Array.splice(arr,...)
  local all = {arr,...}
  local n = 1 + select('#',...)
  local r = {}
  for i=0,#arr-1 do    -- i = key in master table (shifted to 0-indexed)
    for j=1,n do       -- j = current input subtable index
      local s = all[j] -- s = current subtable
      local k = n*i+j  -- k = key in output table (start at 0+1)
      if type(s) == 'table' then
        r[k] = s[i+1]  -- compensate 0-shift
      else
        r[k] = s
        end
      end
    end
  return _toArray(r)
  end


----------
-- Reverse of Array.splice(). Splits a large array into
-- sub-arrays.
-- 
-- @tparam DenseArray|SparseArray arr
-- @tparam NaturalNumber count How many sub-tables should be constructed from
-- the input array. When giving a i,j range it must be divisable by count without
-- rest.
--
-- @tparam[opt=1]    NaturalNumber i First index to process. Mandatory for sparse input.
-- @tparam[opt=#arr] NaturalNumber j Last index to process. Mandatory for sparse input.
--
-- @treturn DenseArray Array of arrays. If the input was made using Array.splice()
-- with non-table inputs then those inputs will __not__ be reconstructed.
-- They will instead return a table with repetitions of the value.
--
-- @usage
--   -- Using the same array as above...
--   local spliced_array = Array.splice({1,2,3},42,{'a','b','c'},nil,'end')
--   -- Which was made of 5 inputs, but one of them was nil, so the
--   -- output is a SparseArray and thus range specification is mandatory.
--   print(spliced_array:fray(5,1,15):to_string())
--   > {{1,2,3}, {42,42,42}, {"a","b","c"}, {nil,nil,nil}, {"end","end","end"}}
--   -- partial ranges will return partial results.
--   print(spliced_array:fray(5,6,10):to_string())
--   > {{2}, {42}, {"b"}, {nil}, {"end"}}
--
function Array.fray(arr,count,i,j)
  -- sanity
  i,j = (i or 1),(j or #arr)
  if (j-i+1)%count ~= 0 then
    stop('Array.fray range must be divisable by count.')
    end  
  -- prepare subtables
  local r = {}
  for i=1,count do r[i] = {} end
  -- fray
  local k = -count -- partial range output index should start at 1
  for m=(i or 1)-1,(j or #arr)-1,count do
    k = k + count
    local n = k/count+1
    for l=1,count do
      r[l][n] = arr[m+l]
      end
    end
  return _toArray(r)
  end

  
----------
-- __In-place.__ Removes subtables, keeps value order.
-- 
-- __Note:__ Recursive tables and factorio objects
-- are not supported and will produce garbage results.
-- 
-- @usage
--   -- a chaotically nested array
--   local arr = {{{{}}},1,2,{3,4,{5,6},{7}},8,{{{{9,{{10}}}}}}}
--   print(Array.flatten(arr):to_string())
--   > {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
-- 
-- @tparam DenseArray arr A nested array.
--
-- @treturn DenseArray
--
function Array.flatten(arr)
  local seen, j = {}, 1
  repeat
    local v = arr[j]
    if type(v) ~= 'table' then
      arr[j] = v
      j = j+1
    else
      -- seen[v] = (not seen[v]) or stop('Recursive arrays can not be flattend.',arr)
      local n2 = #v-1
      if n2 == -1 then
        -- v is an empty table, all elements must be shifted *forward*!
        table_remove(arr,j)
      else
        -- This is a copy of Array.insert_array
        -- tweaked to overwrite the value being inserted.
        local n1, i = #arr, j-1
        for k = n1,  j+1, -1 do arr[k + n2] = arr[k] end -- shift old data back
        for k = 1 , n2+1     do arr[i + k ] = v  [k] end -- insert new data
        end
      end
    until v == nil
  return _toArray(arr)
  end
  
--------------------------------------------------------------------------------
-- Conversion.
-- @section
--------------------------------------------------------------------------------


----------
-- __Experimental.__ Collects the output of a parameterless iterator function into an array.
-- All return values of each call of f_iter() are packed
-- into a sub-array of the output array.
--
-- @tparam function f_iter The iterator function.
--
-- @treturn DenseArray An array of return value arrays.
-- @treturn NaturalNumber The length of the returned array.
--
function Array.from_iterator(f_iter)
  local r,n = {},0
  repeat
    n = n + 1
    r[n] = {f_iter()}
    until Table_size(r[n]) == 0
  r[n],n = nil,n-1 -- loop counts one too far
  return _toArray(r),n
  end

--------------------------------------------------------------------------------
-- Metamethods.
-- @section
--------------------------------------------------------------------------------

--- Concatenation with `\.\.` is Array.extend().
-- @function Array.__concat
_obj_mt.__concat = function(arr,arr2)
  -- syntactic calling must not implicitly change the input!
  return Array.extend(Array.scopy(arr), arr2)
  end

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Array') end
return function() return Array,_Array,_uLocale end

