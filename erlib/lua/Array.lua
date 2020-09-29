-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Numerically indexed table manipulation.
-- Supports 0-indexed arrays?
-- Everything works for sparse arrays?
-- -> The point of this whole module is to be *fast*. 
--    So any slow operations like MixedTable2Array should be in Table!
-- 
-- __Note:__ All methods of this module that return an array also set the
-- metatable of the result to this module, except for in-place methods that
-- recieve an input that already had a metatable.
--
-- __Note:__ Most methods of this module directly apply their result to the 
-- input table. If you want the input table to be unaffected you can supply
-- feed an (empty) table as the _target_ to which the result should be copied.
-- This allows both in-place and copy operations to be performed without
-- additional overhead.
--
-- __Note:__ This module inherits all @{Table} module methods. Same-named
-- Array methods override inherited Table methods.
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

local setmetatable, getmetatable, pairs
    = setmetatable, getmetatable, pairs

local math_floor, math_ceil
    = math.floor, math.ceil

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
local _toArray = function(tbl)
  if not getmetatable(tbl) then setmetatable(tbl,_obj_mt) end
  return tbl end
do setmetatable( Array,{__call = function(_,tbl) return _toArray(tbl) end}) end
do setmetatable(_Array,{__call = function(_,tbl) return _toArray(tbl) end}) end


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
-- Methods.
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
-- __In-place.__ Compresses a @{SparseArray} into a @{DenseArray}. The order of the elements
-- is preserved. Can also compress partial ranges of the input, for example to
-- split the compression into multiple steps.
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
-- __never changes the keys__ of an array. If the result is sparse or dense depends
-- on if f() ever returns nil, or if the input array or partial range include
-- nil values.
-- 
-- @tparam DenseArray|SparseArray arr
-- @tparam function f The function f(value,index,arr) that is applied to every
-- key→value mapping in the array.
-- @tparam[opt=nil] table target __Copy Mode.__ This table will be changed and arr remains unchanged.
--
-- @tparam[opt=1]    NaturalNumber i First index to process. Mandatory for sparse input.
-- @tparam[opt=#arr] NaturalNumber j Last index to process. Mandatory for sparse input.
--
-- @treturn DenseArray|SparseArray
function Array.map(arr,f,target,i,j)
  target = target or arr
  for k=(i or 1),(j or #arr) do
    target[k] = f(arr[k],k,arr)
    end
  return _toArray(target)
  end
 
 
----------
-- __In-place.__ Removes elements from an array based on a filter function.
--
-- @tparam DenseArray|SparseArray arr
-- @tparam function f Any elements for which the filter function f(value,index,arr)
-- does not return @{Concepts.truthy|truthy} are removed from the array. And any
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
function Array.try_unique_insert(arr,value,i)
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
  return _toArray(arr), count
  end
  
  
----------
-- __In-place.__ Moves the value at position #arr to position key.
-- For large arrays this is __much faster__ than @{table.remove}
-- but does not preserve element order.
--
-- @tparam DenseArray arr
-- @tparam AnyValue key
--
-- @treturn DenseArray The input array.
--
function Array.unsorted_remove_key(arr,key)
  local n = #arr
  if key <= n then -- properly ignore after-the-end keys
    arr[key],arr[n] = arr[n],nil
    end
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
  local r = {}
  for k=(i or 1),(j or #arr) do
    r[k] = arr[k]
    end
  return _toArray(r)
  end



-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Array') end
return function() return Array,_Array,_uLocale end
