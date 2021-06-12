-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Table manipulation.
--
-- __Note:__ This module inherits all native-Lua @{table} module methods unless
-- overwritten by same-named local methods.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Experimental 2020-10-31.
--
-- @module Table
-- @usage
--  local Table = require('__eradicators-library__/erlib/lua/Table')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

local table_size, pairs, type, rawget, setmetatable, getmetatable,
      debug_setmetatable, table_sort
    = table_size, pairs, type, rawget, setmetatable, getmetatable,
      debug.setmetatable, table.sort

local NIL
    = ercfg.NIL
    
local stop = elreq('erlib/lua/Error')().Stopper('Table')
    
local String = elreq('erlib/lua/String')()

local Replicate = elreq('erlib/lua/Replicate')()
local Twice = Replicate.Twice
    
local Verificate = elreq('erlib/lua/Verificate')()
local isNaturalNumber = Verificate.isType.NaturalNumber
local isPlainTable    = Verificate.isType.PlainTable
    
-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

-- CONCEPT __MUTATE__ or __CREATE__ on every function, seperate sections
-- + Table.apply as in-place variant of Table.map


local Table,_Table,_uLocale = {},{},{}

Table.NIL      , _Table.NIL      = Twice(NIL)



-- -------------------------------------------------------------------------- --
-- Metatable                                                                  --
-- -------------------------------------------------------------------------- --

-- Inherit all Table methods.
for k,v in pairs( table) do  Table[k] = v end
-- for k,v in pairs(_Table) do _Table[k] = v end

local _obj_mt = {__index=Table}
-- attach meta if safe
local _toTable = function(tbl)
  if not getmetatable(tbl) then setmetatable(tbl,_obj_mt) end
  return tbl end
-- attach meta if really safe
local _toTableIfTable = function(obj)
  if isPlainTable(obj) then return _toTable(obj) else return obj end
  end
-- user request to attach meta unconditionally
do setmetatable( Table,{__call = function(_,tbl) return setmetatable(tbl,_obj_mt) end}) end
do setmetatable(_Table,{__call = function(_,tbl) return setmetatable(tbl,_obj_mt) end}) end


--------------------------------------------------------------------------------
-- Module.
-- @section
--------------------------------------------------------------------------------

-- -------
-- Nothing.
-- @within Todo
-- @field todo1


----------
-- Attaches the Table modules metatable to any table.
-- @tparam table tbl
-- @treturn Table The unchanged input table.
-- @function Table
do end

----------
-- Workaround to put <nil> values into tables. Lua can not usually put
-- @{nil} as keys or values in tables because it treats those as not to be
-- in the table in the first place. For situations where you need to put
-- nil values into tables Erlib offers to use this unique @{string} that
-- certain functions like @{Table.remove_nil}, @{Table.set} or @{Table.patch}
-- will recognize as nil value.
-- 
-- @field Table.NIL
do end

--------------------------------------------------------------------------------
-- Basic Methods.
-- @section
--------------------------------------------------------------------------------

----------
-- Counts @{key -> value pairs}. Uses factorio @{FAPI Libraries table_size} when
-- available.
--
-- @tparam table tbl
--
-- @treturn NaturalNumber The total number of keys in this table. Counts all
-- types of keys including numeric.
--
-- @function Table.size
Table.size = (
  -- factorio C-side counting is faster if available.
  (flag.IS_FACTORIO and table_size)
  and function(self) return table_size(self) end
  or  function(self) local n = 0 for _ in pairs(self) do n=n+1 end return n end
  )

  
----------
-- The largest numeric key in the array part of this table.
-- For @{DenseArray}s 
-- @{The Length Operator|the length operator #} is __much faster__.  
--
-- @tparam MixedTable tbl A table with a sparse array part.
--
-- @treturn NaturalNumber
--
function Table.array_size(tbl)
  local last = 0
  for i in pairs(tbl) do
    if type(i) == 'number'
    and i % 1 == 0 -- isNaturalNumber without decimal points
    and i > last then
      last = i
      end
    end
  return last end
  
  
----------
-- Generates a @{DenseArray} of @{NaturalNumber}s.
--
-- @tparam[opt=1] NaturalNumber a
-- @tparam NaturalNumber b The end of the range (inclusive).
-- @tparam[opt] NaturalNumber step 
--
-- @treturn DenseArray
--
-- @usage
--   print(Table.range(10))
--   > {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
--   print(Table.range(5,10))
--   > {5, 6, 7, 8, 9, 10}
--   print(Table.range(2,44,4))
--   > {2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42}
--
function Table.range(a,b,step)
  local r = {}
  for i=(b and a or 1),(b or a),(step or ((b and a>b) and -1) or 1) do
    r[#r+1]=i
    end
  return _toTable(r)
  end
function _Table.range(a,b,step)
  Verify(a   ,    'NaturalNumber')
  Verify(b   ,'nil|NaturalNumber')
  Verify(step,'nil|NaturalNumber') -- step requires a AND b
  return true end


----------
-- Generates an unsorted DenseArray from the values of tbl.
--
-- @tparam table tbl
--
-- @treturn DenseArray
--
function Table.values(tbl)
  local r = {}
  for _,v in pairs(tbl) do
    r[#r+1] = v
    end
  return _toTable(r)
  end
  
  
----------
-- Generates an unsorted DenseArray from the keys of tbl.
--
-- @tparam table tbl
--
-- @treturn DenseArray
--
function Table.keys(tbl)
  local r = {}
  for k in pairs(tbl) do
    r[#r+1] = k
    end
  return _toTable(r)
  end


----------
-- Creates a new table in which @{key <-> value mappings} are swapped.
-- Duplicate values will be mapped to the __last__ key that references them
-- but due to the behavior of @{next} it's undefind behavior which key that
-- will be. In factorio pairs is deterministic and it should thus be the
-- key that was added to the table last.
-- 
-- @tparam table tbl
-- 
-- @treturn table A new flipped table.
-- 
-- @usage
--   local my_table = {'a','b','c','c'}
--   print(Table(my_table):flip():to_string())
--   > {a = 1, b = 2, c = 4}
-- 
--   print(Hydra.lines(Table(defines.events):flip()))
--   > {
--       [0] = "on_tick"
--       [1] = "on_gui_click",
--       [2] = "on_gui_text_changed",
--       [3] = "on_gui_checked_state_changed",
--       [4] = "on_entity_died",
--       [5] = "on_picked_up_item",
--       ...
--       }
--
function Table.flip(tbl)
  local r = {}
  for k,v in pairs(tbl) do r[v] = k end
  return _toTable(r)
  end
  
----------
-- Wraps the object in a table if it is not already a table.
-- @tparam AnyValue obj
-- @treturn Table
function Table.plural(obj)
  -- if  type(obj) == 'table'
  -- and type(obj.__self) ~= 'userdata' then
  if isPlainTable(obj) then
    return _toTable(obj)
  else
    return _toTable{obj}
    end
  end

  
----------
-- __Deep compare.__ If two tables have exactly the same content.
--
-- __Note:__ Does not compare the content of tables-as-keys.
--
-- @tparam table tbl
-- @tparam table tbl2
--
-- @treturn boolean
--
-- @usage
--   local a = {1,2,3,4}
--   local b = {5,6,7,8}
--   local c = {'a','b','c','d'}; c[5] = c
--   local test1 = {a=a,b={b=b,c={c=c}}}
--   local test2 = {a=a,b={b=b,c={c=c}}}
--   print(test1 == test2)
--   > false
--   print(Table.is_equal(test1,test2))
--   > true
--
function Table.is_equal(tbl,tbl2)
  local function _isequ(A,B)
    -- primitively equal?
    if A == B then return true end -- works for userdata and other custom __equ
    -- type equal?
    local typeA, typeB = type(A), type(B)
    if typeA ~= typeB then return false end
    -- anything that's (not a table) and (not A==B) can not be equal
    if typeA ~= 'table' then return false end
    -- does B have different keys?
    for k in pairs(B) do if         A[k] == nil then return false end end
    -- do all keys in A map the same key in B?
    for k in pairs(A) do if not _isequ(A[k],B[k]) then return false end end
    return true
    end
  return _isequ(tbl,tbl2)
  end

  
----------
-- Returns true if the table contains no values.
-- @tparam table tbl
-- @treturn boolean
function Table.is_empty(tbl)
  for _ in pairs(tbl) do return false end
  return true
  end

  
----------
-- Converts empty tables into a @{nil} value.
-- @tparam table|nil tbl
-- @treturn table|nil  
function Table.nil_if_empty(tbl)
  for _ in pairs(tbl) do return _toTable(tbl) end
  end


--------------------------------------------------------------------------------
-- Other Methods.
-- @section
--------------------------------------------------------------------------------

  
----------
-- Creates patterned and unpatterened table repetitions.
-- __Either count or patterns or both must be given.__
--
-- @tparam table tbl
-- @tparam[opt] NaturalNumber variation_count How many repetitions to create.
-- Will use the length of the first patterned key if not given.
-- @tparam[opt] table patterns A table that maps each key to a DenseArray
-- of at least length variation_count.
-- 
--
-- @treturn table
--
-- @usage
--   -- Simple example. Patternless repetition.
--   local test = Table.rep({1,2,3},3)
--   print(Hydra.lines(test))
--   > {
--   >   {1, 2, 3},
--   >   {1, 2, 3},
--   >   {1, 2, 3}
--   > }
--
-- @usage
--   -- Intermediate example. Patterned repetition.
--   local test = Table.rep({},3,{name = {'Peter','Paula','Alex'}})
--   print(Hydra.lines(test))
--   > {
--   >   {name = "Peter"},
--   >   {name = "Paula"},
--   >   {name = "Alex"}
--   > }
--
-- @usage
--   -- Advanced example.
--   -- Creating a Gui.construct compatible layout for a simple calculator.
--   
--   local buttons = {
--     1 , 2 , 3 ,'+','-',
--     4 , 5 , 6 ,'*','/',
--     7 , 8 , 9 ,'(',')',
--     0 ,'.','←','C',
--     }
--
--   local layout = Table.rep(
--     {'button'},
--     nil, -- You can automatically use #buttons length derived from #caption.
--     {
--       caption=buttons,
--       path = Table.rep( -- Nested call first creates a variation table.
--         {'buttons'},
--         #buttons, -- Or you can specify the length manually.
--         {[2]=buttons}
--         )
--       }
--     )
--
--   print(Hydra.lines(layout))
--   > {
--       {"button", caption =  1 , path = {"buttons",  1 }},
--       {"button", caption =  2 , path = {"buttons",  2 }},
--       {"button", caption =  3 , path = {"buttons",  3 }},
--       {"button", caption = "+", path = {"buttons", "+"}},
--       {"button", caption = "-", path = {"buttons", "-"}},
--       {"button", caption =  4 , path = {"buttons",  4 }},
--       {"button", caption =  5 , path = {"buttons",  5 }},
--       {"button", caption =  6 , path = {"buttons",  6 }},
--       {"button", caption = "*", path = {"buttons", "*"}},
--       {"button", caption = "/", path = {"buttons", "/"}},
--       {"button", caption =  7 , path = {"buttons",  7 }},
--       {"button", caption =  8 , path = {"buttons",  8 }},
--       {"button", caption =  9 , path = {"buttons",  9 }},
--       {"button", caption = "(", path = {"buttons", "("}},
--       {"button", caption = ")", path = {"buttons", ")"}},
--       {"button", caption =  0 , path = {"buttons",  0 }},
--       {"button", caption = ".", path = {"buttons", "."}},
--       {"button", caption = "←", path = {"buttons", "←"}},
--       {"button", caption = "C", path = {"buttons", "C"}}
--     }

function Table.rep (tbl,variation_count,patterns)
  --[[Note: patternless replication is pretty common/useful too.]]
  local r = {}
  if variation_count == nil then
    variation_count = #Table.first_value(patterns)
    end
  for variation_index=1,variation_count do
    local new = Table.scopy(tbl)
    for key,variations in pairs(patterns or {}) do
      -- wait and see if this is nessecary/obstructive
      -- Verify(new[key],'nil','patterned key is already in table',tbl,patterns)
      -- Verify(variations[variation_index],'not_nil','patterns was empty',tbl,patterns)
      new[key] = variations[variation_index]
      end
    r[#r+1] = Table.dcopy(new) --@future: fcopy?
    end
  return _toTable(r)
  end
  
----------
-- __In-place.__ Shallowly replaces @{Table.NIL} keys and values with @{nil},
-- deleting the affected mappings.
--
-- @tparam table tbl
-- 
-- @treturn tbl
-- 
function Table.remove_nil(tbl)
  for k,v in pairs(tbl) do
    if (k == NIL) or (v == NIL) then
      tbl[k] = nil
      end
    end
  return _toTable(tbl)
  end
  
--------------------------------------------------------------------------------
-- Conversion.
-- @section
--------------------------------------------------------------------------------

----------
-- __In-place.__ Converts MixedTable to SparseArray. All keys that are not
-- @{NaturalNumber}s will be removed.
--
-- @tparam table tbl 
-- @tparam[opt=nil] table target __Copy Mode.__ This table will be changed and
-- tbl remains unchanged.
--
-- @treturn SparseArray|DenseArray A table containing only the numeric keys
-- of the input array.
--
function Table.to_array(tbl,target)

  -- Comment: i,j range based methods are in Array
  --          so this doesn't need to support i,j.
  
  if target then
    for k,v in pairs(tbl) do
      if isNaturalNumber(k) then target[k] = v end
      end
    return _toTable(target)
  else
    for k in pairs(tbl) do
      if not isNaturalNumber(k) then tbl[k] = nil end
      end
    return _toTable(tbl)
    end
  end

----------
-- __Alias__ of @{String.to_string}.
--
-- @tparam table tbl
-- @treturn string
--
-- @function Table.to_string
Table.to_string = String.to_string
  
--------------------------------------------------------------------------------
-- Search Methods.
-- @section
--------------------------------------------------------------------------------

----------
-- Finds the largest element in a table.
-- 
-- @tparam table tbl
-- @tparam[opt] function gtr A comparitor function f(a,b)→boolean that
-- returns true when a is larger than b. Defaults to a>b.
-- 
-- @treturn AnyValue The __value__.
-- @treturn NotNil The __key__ of the __first__ occurance of value in tbl.
--
function Table.find_largest(tbl,gtr)
  local lv,lk = Table.next_value(tbl)
  if not gtr then
    -- native comparison is faster than calling a function
    for k,v in pairs(tbl) do if v > lv    then lv,lk = v,k end end
  else
    for k,v in pairs(tbl) do if gtr(v,lv) then lv,lk = v,k end end
    end
  return lv,lk
  end

  
----------
-- Retrieves the key of a value.
--
-- @tparam table tbl
-- @tparam NotNil value
--
-- @treturn NotNil|nil  The key of the __first occurance__ of the value,
-- or nil if value wasn't found. 
--
function Table.find(tbl, value)
  for k, v in pairs(tbl) do
    if v == value then return k end
    end
  end
  
----------
-- Fetches the next value in a table. Respects __pairs metamethod. Return
-- value order is reversed compared to lua @{next}. By default will return
-- the __first__ value of a table.
-- 
-- @tparam table tbl
-- @tparam[opt=nil] AnyValue key The key __preceeding__ the output key.
-- 
-- @treturn AnyValue The __value__.
-- @treturn AnyValue The __key__ of above value in tbl.
-- 
function Table.next_value(tbl,key)
  local next,tbl = pairs(tbl)
  local k   ,v   = next(tbl,key)
  return v,k
  end

----------
-- Shortcut to Table.next_value(tbl,nil) that doesn't return the key at all.
--
-- @tparam table tbl
--
-- @treturn AnyValue The __value__.
--
function Table.first_value(tbl)
  -- Usually shortcuts shouldn't be in the library, but this is 
  -- very common and *much* easier to read.
  return (Table.next_value(tbl,nil))
  end

  
--------------------------------------------------------------------------------
-- Path Methods.
-- @section
--------------------------------------------------------------------------------

----------
-- __Concept.__
-- A @{DenseArray} of values that represent keys of a nested path in another table.
--
-- @table TablePath


----------
-- Get the value at location path in tbl.
-- 
-- @tparam table tbl
-- @tparam table path
-- @tparam[opt=nil] AnyValue default The value that will be returned if the full path points
-- at a nil value or if the path only partially exists in tbl.
-- 
-- @usage
--   local tbl = {a = {b = {c = 42}}}
--   local path = {'a','b','c'}
--   print (Table(tbl):get(path))
--   > 42
-- 
-- @usage
--   local tbl = {a = {b = {c = 42}}}
--   local path = {'a','b','c','d','e'}
--   print (Table.get(tbl,path,"Don't panic!"))
--   > Don't panic!
-- 
-- @treturn NotNil|nil 
-- 
function Table.get(tbl,path,default)
  -- path actually allows MixedTable
  -- the extra data in the non-array part must be silently ignored
  local r = tbl
  for i=1,#path do
    if type(r) == 'table' then
      r = r[ path[i] ]
    else
      return default -- can be nil
      end
    end
  if r ~= nil then
    return r
  else
    return default
    end
  end

  
----------
-- Set a new value to location path in tbl. Automatically creates subtables
-- nessecary to fullfill the path.
-- 
-- @tparam table tbl
-- @tparam table path
-- @tparam AnyValue value
-- 
-- @treturn value A reference to the input value given.
-- 
function Table.set(tbl,path,value)
  local r = tbl
  local n = #path
  for i=1,n-1 do
    local k = path[i]
    if r[k] == nil then r[k] = {} end -- checking type(r[k])=='table') makes it slower.
    r = r[k]
    end
  if value == NIL then value = nil end
  r[path[n]] = value
  -- return _toTableIfTable(value) --@2021-06-11 Let's see if removing it breaks anything.
  return value
  end

  
----------
-- Get the value at location path in tbl if it exists, otherwise creates it.
-- Automatically creates subtables nessecary to fullfill the path.
-- 
-- @tparam table tbl
-- @tparam table path
-- @tparam AnyValue default
-- 
-- @treturn AnyValue A reference to the found value or the default value.
-- 
function Table.sget(tbl,path,default)
  local r = tbl
  local n = #path
  for i=1,n-1 do
    local k = path[i]
    if r[k] == nil then r[k] = {} end -- checking type(r[k])=='table') makes it slower.
    r = r[k]
    end
  local k = path[n]
  if r[k] == nil then r[k] = default end -- NIL makes no sense here
  -- return _toTableIfTable(r[k])
  return r[k] --@2021-06-11 Let's see if removing it breaks anything.
  end


----------
-- Adds a number to an existing value or creates a new value.
--
-- __Alias:__ `Table\['+='\]\(t,p,n\)`
--
-- @tparam table tbl
-- @tparam table path
-- @tparam number number
--
-- @function Table.add
Table['+='], Table.add = Twice(function(tbl, path, number)
  Table.set(tbl, path, number + (Table.get(tbl, path) or 0))
  end)

  
----------
-- Removes and returns a value from a table.
--
-- Does _not_ remove empty sub-tables left behind after removing all keys.
--
-- __Note:__ Not to be confused with @{LMAN table.remove} which only works on arrays.
--
-- @tparam table tbl
-- @tparam TablePath path
--
-- @treturn AnyValue
--
function Table.remove(tbl, path)
  local value = Table.get(tbl, path)
  Table.set(tbl, path, nil);
  return value
  end
  
  
----------
-- __Concept.__
-- A @{DenseArray} consisting of a @{Table.TablePath|TablePath} followed by a
-- @{Table.TablePatchValue|TablePatchValue}.
--
-- @table TablePatch
  
----------
-- __Concept.__  
-- The value part of a @{Table.TablePatch|TablePatch} is not further interpreted
--  __unless__ it is a @{MixedTable} made of a @{Table.TablePath|TablePath}
-- that contains the mapping `{self=true}`. In this case the actual value
-- will be fetched from the table being patched. Mainly used for in-line self
-- refernces during data-stage prototype creation.
--
-- @tfield[opt=nil] boolean self Unless this is @{true} the whole table is the value.
-- @tfield[opt=true] boolean copy By default self-referencing values will be
-- copied. Set this to false if you want to use a direct reference instead.
-- @table TablePatchValue
  
  
----------
-- Takes an array of patches and applies them to a table.
--
-- @tparam table tbl
-- @tparam DenseArray patches An array of @{Table.TablePatch|TablePatch}.
--
-- @treturn table The input table.
--
-- @usage
--   local test = {one = 1}
--   Table(test)
--     :patch({{'two',value=2}})
--   test:patch({
--     {'deeper','one',value={self=true,copy=true,'one'}},
--     {'deeper','two',value={self=true,copy=true,'two'}},
--     })
--   print(Hydra.line(test))
--   > {deeper = {one = 1, two = 2}, one = 1, two = 2}
--
function Table.patch(tbl,patches)
  --{'a','b','c','d',value={self=true,copy=false,'c','d','e'}}
  for i=1,#patches do
    local patch = patches[i]
    if type(patch) ~= 'table' then
      stop('Patches must be tables',patches)
      end
    if patch[1] == nil then
      stop('Patch has no target path.')
      end
    local v = patch.value
    -- is v a self-referencing path?
    if type(v) == 'table' and v.self == true then
      if v.copy == false then
        v = Table.get(tbl,v)
      else
        v = Table.dcopy(Table.get(tbl,v))
        end
      if v == nil then
        stop('Self-referencing patch value was nil!',
          '\npatch: ',patch,
          '\ntable: ',tbl
          )
        end
      end
    Table.set(tbl,patch,v) -- can be NIL
    end
  return _toTable(tbl)
  end

  
  
--------------------------------------------------------------------------------
-- In-Place Methods.
-- @section
--------------------------------------------------------------------------------

----------
-- __In-place.__ Removes a @{key->value pair} and returns the value.
-- Alternatively replaces the old value with a new value.
-- Does __not__ change the order of the remaining elements.
--
-- @tparam table tbl
-- @tparam NotNil key
-- @tparam[opt=nil] AnyValue value The new value to put into the table.
--
-- @treturn AnyValue 
--
function Table.pop(tbl, key, value)
  value, tbl[key] = tbl[key], value
  return value
  end

  
----------
-- __In-place.__ Applies a function to all elements of a table.
--
-- __Experts only:__ Table.map in __Copy Mode__ supports changing the key
-- that a value is associated with. If f(value,key,tbl) returns __two__ values
-- then the first is the new value and the second is the new key. If it returns
-- __one__ value then the original key will be used. This check is done for 
-- each key→value pair seperately.
--
-- @tparam table tbl
-- @tparam function f The function f(value,key,tbl) that produces the new value
-- for each key→value mapping in the table.
-- @tparam[opt=nil] table target __Copy Mode.__ The result of the operation will
-- be written to this table and tbl remains unchanged.
--
-- @treturn table The input table.
--
function Table.map(tbl,f,target)
  local copy_mode = not not target
  target = target or tbl
  if not copy_mode then
    for k,v in pairs(tbl) do
      target[k] = f(v,k,tbl)
      end
  else
    -- reassignment is only supported in copy_mode because 
    -- next() does not allow adding new keys during iteration.
    for k,v in pairs(tbl) do
      local v2,k2 = f(v,k,tbl)
      if k2 == nil then
        target[k ] = v2
      else
        target[k2] = v2
        end
      end
    end
  return _toTable(target)
  end


----------
-- __In-place.__ Removes elements from a table based on a filter function.
-- 
-- @tparam table tbl
-- @tparam function f If calling f(value,key,tbl) does not return @{truthy} 
-- then the value will be removed from the table.
-- 
-- @tparam[opt=nil] table target __Copy Mode.__ The result of the operation will
-- be written to this table and tbl remains unchanged.
-- 
-- @treturn table The input table.
-- 
function Table.filter(tbl,f,target)
  local copy_mode = not not target
  target = target or tbl
  if not copy_mode then
    for k,v in pairs(tbl) do if not f(v,k,tbl) then target[k] = nil end end
  else
    for k,v in pairs(tbl) do if     f(v,k,tbl) then target[k] = v   end end
    end
  return _toTable(target)
  end
  

----------
-- __In-place.__ __Shallow Merge.__ Copies data from one table into another.
-- Copies only the first layer of the table. All sub-table references stay
-- identical.
--
-- @tparam table tbl
-- @tparam[opt] table tbl2 The table from which to take the data.
--
-- @treturn table The input table.
--
function Table.smerge(tbl,tbl2)
  if tbl2 then
    for k,v in pairs(tbl2) do
      tbl[k] = v
      end
    end
  return _toTable(tbl)
  end

----------
-- __In-place.__ @{LMAN table.sort} with table return.
--
-- @tparam table tbl
-- @tparam function comp
--
-- @treturn table The input table.
--
function Table.sort(tbl, comp)
  table_sort(tbl, comp)
  return _toTable(tbl)
  end
  
----------
-- __In-place.__ Inserts value into tbl __only if__ no other key in the table
-- has an == equal value.
-- 
-- @tparam table tbl
-- @tparam NotNil key
-- @tparam AnyValue value
-- 
-- @treturn table The input table.
-- 
function Table.insert_once(tbl,key,value)
  for _,v in pairs(tbl) do
    if v == value then return _toTable(tbl) end
    end
  tbl[key] = value
  return _toTable(tbl)
  end



----------
-- __In-place.__ Removes all key→value mappings from a table.
-- 
-- @tparam table tbl
-- @tparam DenseArray except_keys These keys will not be deleted.
-- @tparam[opt=true] boolean is_whitelist If set to false *only* the except_keys will be deleted.
--
-- @treturn table The now empty input table.
--
function Table.clear(tbl,except_keys,is_whitelist)
  if not except_keys then
    for k in pairs(tbl) do tbl[k] = nil end
    return _toTable(tbl)
  else
    -- whitelist, keep only listed keys (default)
    if is_whitelist ~= false then
      local keep = {}; for _,k in pairs(except_keys) do keep[k] = true end
      for k in pairs(tbl) do if not keep[k] then tbl[k] = nil end end
      return _toTable(tbl)
    -- blacklist, keep only unlisted keys
    else
      for _, k in pairs(except_keys) do tbl[k] = nil end
      return _toTable(tbl)
      end
    end
  end


----------
-- __In-place.__ Puts the content of one table into the reference of another.
-- Used when you need to replace all content of a table, but need to keep
-- external references to the table intact.
-- 
-- @tparam table table_reference All key→value mappings in this table will be deleted.
-- @tparam table value_table All key→value mappings will be __shallowly copied__
-- into table_reference.
-- 
-- @treturn Table The input table reference with the
-- 
-- @function Table.overwrite
--
-- @usage
--   local my_table  = {1,2,3}
--   local also_my_table = my_table
--   local my_values = {'a','b','c'}
--   Table.overwrite(my_table,my_values)
--   print(my_table:to_string())
--   > {"a", "b", "c"}
--   print(my_table == my_values)
--   > false
--   print(my_table == also_my_table) -- all local references stay intact
--   > true
--  
function Table.overwrite(tbl,tbl2)
  for k   in pairs(tbl ) do tbl[k] = nil end --clear
  for k,v in pairs(tbl2) do tbl[k] = v   end --smerge
  return _toTable(tbl)
  end
  
  
----------
-- __In-place.__ Applies a series of migration functions to sub-table.
-- 
-- @tparam table tbl
-- @tparam NotNil index The index of the to-be-migrated subtable in tbl. If
-- the index does not yet exist it will be initialized as an empty table.
-- @tparam SparseArray migrations A group of to-be-sequentially-applied
-- migration functions. Each function will be called f(tbl[index],index,tbl,...).
-- @tparam[opt] AnyValue ... Arbitrary extra data that will be passed to each
-- migration function.
--
-- @treturn The fully migrated subtable.
--
-- @usage
--   local my_data = {
--     ['Peter'] = {
--       -- No version means _version=0
--       name = 'Peter',
--       },
--     ['Paula'] = {
--       -- _version is internally managed and should not be manually changed.
--       _version = 1,
--       value = 12,
--       givenname = 'Paula',
--       }
--     }
--     
--   local my_migrations = {
--     -- The number indicates that version this function *outputs*
--     -- Usually you will only need (data).
--     [1] = function(data)
--       -- Rename old values.
--       data.givenname = data.name
--       data.name      = nil 
--       -- Initialize newly implemented values.
--       data.value     = 0
--       -- _version can *NOT* be manually changed during a migration.
--       data._version  = 42 -- this has no effect
--       end,
--     -- But sometimes extra parameters are useful.
--     [2] = function(data,index,tbl,bonus,superbonus)
--       -- Migrations can completely reconstruct the table.
--       tbl[index] = {
--         gnam = data.givenname or index,
--         val  = data.value + bonus + (superbonus or 0)
--         }
--       end,
--     }
--   
--   -- You can migrate old data.   
--   for k,_ in pairs(my_data) do
--     Table.migrate(my_data,k,my_migrations,30)
--     print(k,':',Table(my_data[k]):to_string())
--     end
--   > Paula : {_version = 2, gnam = "Paula", val = 42}
--   > Peter : {_version = 2, gnam = "Peter", val = 30}
--
--   -- Or you can create new data.
--   Table.migrate(my_data,'Alex',my_migrations,1,9000) -- with superbonus
--   print('Alex :',Table(my_data['Alex']):to_string())
--   > Alex  : {_version = 2, gnam = "Alex", val = 9001}
--
function Table.migrate (tbl, index, migrations, ...)
  -- Code Annotations:
  --  * index should be a plain number to keep the data small and
  --    easily processable. Allowing x.y.z version strings just
  --    makes everything more complicated and expensive.

  -- init
  local node = tbl[index] or {}; tbl[index] = node -- Table.sget()
  local current_version  = node._version or node.__version or 0 --legacy names
  local latest_migration = Table.array_size(migrations) or 0
  -- migrate
  for version = 1 + current_version, latest_migration do
    local f = migrations[version]
    if f then
      f(node,index,tbl,...)
      node = tbl[index] --f is allowed to assign a new table to tbl[index]
      node._version = version -- version tag is enforced and fully automatic
      end
    end
  return node
  end

  
  
--------------------------------------------------------------------------------
-- Copy Methods.
-- @section
--------------------------------------------------------------------------------


----------
-- __Shallow Copy.__ Copies the first level of the table such that all
-- __sub-table references stay identical__ to the original table.
--
-- @tparam AnyValue tbl
--
-- @treturn table The new table.
--
function Table.scopy(tbl)
  -- Annotation:
  --  * First tparam is documented as AnyValue because that's actually
  --    what's supported, but the intended purpose is copying tables,
  --    so the parameter should be called tbl not obj.
  if not isPlainTable(tbl) then
    return tbl
  else
    local r = {}
    for k,v in pairs(tbl) do r[k] = v end
    return _toTable(r)
    end
  end
  

----------
-- __Deep Copy.__ A copy of a table that shares none of the original table
-- references but has the __same self-referencing__ structure.
-- 
-- @tparam AnyValue tbl
-- @tparam[opt=false] boolean remove_metatables Removes metatables from
-- tbl and all sub-tables.
--
-- @treturn table The new table.
-- 
function Table.dcopy(tbl,remove_metatables)
  --based on factorio_0.17.74/data/core/lualib/util.lua
  --@future: is iterative / non-recursive faster?
  local seen = {}
  local function _copy(this)
    if not isPlainTable(this) then
      return this
    elseif seen[this] then
      return seen[this]
    else
      local r = {}; seen[this] = r
      for k,v in pairs(this) do
        r[_copy(k)] = _copy(v)
        end
      if not remove_metatables then
        return setmetatable(r,getmetatable(this)) -- copy meta? usecase?
      else
        return r
        end
      end
    end
  -- Table metatable can only be attached to table types but should only
  -- be attached to the outer shell, not all subtables.
  return _toTableIfTable(_copy(tbl))
  end
  
----------
-- __Full Copy.__ A copy of a table that shares none of the original table
-- references and in which all formerly self-referenced __sub-tables are made
-- unique__.
-- Mostly useful for visual inspection of complex tables.
-- 
-- @tparam AnyValue tbl
-- @tparam[opt=false] boolean remove_metatables Removes metatables from
-- tbl and all sub-tables.
--
-- @treturn table The new table.
-- 
function Table.fcopy(tbl,remove_metatables)
  -- seperate from Table.dcopy() to keep dcopy lean and fast
  local function _copy(this,depth)
    if type(this) ~= 'table'
    --detection of factorio objects ignores meta
    or type(rawget(this,'__self')) == 'userdata' then
      return this
    elseif depth > 10000 then
      err('Table too deep for full_copy. Possible recursion.')
    else
      local r = {}
      for k,v in pairs(this) do
        r[_copy(k,depth+1)] = _copy(v,depth+1)
        end
      if not remove_metatables then
        return setmetatable(r,getmetatable(this)) -- copy meta? usecase?
      else
        return r
        end
      end
    end
  return _toTableIfTable(_copy(tbl,0))
  end

  

  
--------------------------------------------------------------------------------
-- Metamethods.
-- @section
--------------------------------------------------------------------------------

--- Addition with + is Table.smerge().
-- @function Table.__concat
_obj_mt.__add = function(tbl,tbl2)
  -- syntactic calling must not implicitly change the input!
  return Table.smerge(Table.scopy(tbl),tbl2)
  end

----------
-- Set a function as metamethod of tbl.
-- Inherits current metatable or creates a new one.
-- Will __overwrite__ existing metamethods of the same name.
--
-- @tparam table tbl
-- @tparam string method_name "\_\_index", "\_\_newindex", etc.
-- @tparam function|nil f A meta handler f(self,...).
--
-- @treturn table This does __not__ automatically inherit any methods of this
-- Table module.
--
function Table.set_metamethod(tbl,method_name,f)  
  local mt = getmetatable(tbl) or {}
  mt[method_name] = f
  return setmetatable(tbl,mt)
  end

  
----------
-- Gets the metamethod handler function of tbl.
--   
-- @tparam table tbl
-- @tparam string method_name "__index", "__newindex", etc.
--
-- @treturn function
--  
function Table.get_metamethod(tbl,method_name)
  -- Table.has_metamethod can be emulated with this.
  local mt = getmetatable(tbl)
  if mt then return mt[method_name] end --can be nil
  end



--[[-------
  Recursively removes metatables from all subtables but not from other object types.

  @tparam table tbl
  
  @treturn table The input table. *Doesn't* have a Table module metatable.

  @usage
    local test = setmetatable({},{
      __index = function() print'first meta' return 1 end,
      })
    -- recursive
    test.test = test
    -- different
    test.foo  = setmetatable({},{
      __index = function() print'second meta' return 2 end,
      })
    
    -- metamethods will trigger additional printing
    local x = test[1]
    > first meta
    local x = test.test[1]
    > first meta
    local x = test.foo[1]
    > second meta
    
    Table.deep_clear_metatables(test)

    -- without metatables there is no printing (and also no values in this case).
    local x = test[1]
    local x = test.test[1]
    local x = test.foo[1]
  ]]
function Table.deep_clear_metatables(tbl)
  local seen = {}
  local function _clear(obj)
    -- if  type(obj) == 'table'
    if  isPlainTable(obj)
    and seen[obj] ~= true then
      seen[obj] = true
      debug_setmetatable(obj,nil)
      for k,v in pairs(obj) do
        _clear(k)
        _clear(v)
        end
      end
    return obj
    end
  return _clear(tbl)
  end
  

----------
-- Removes the metatable from a table.
-- Does not recurse into the table. Useful for finalizing tables in data stage,
-- when the automatically attached metatables of a @{Table}, @{Array}, @{Set}
-- etc. shouldn't be inherited into data.raw.
-- 
-- @tparam table tbl
-- @treturn table The input table. *Doesn't* have a Table module metatable.
function Table.clear_meta(tbl)
  return debug_setmetatable(tbl,nil)
  end

  
--------------------------------------------------------------------------------
-- Factories.
-- @section
--------------------------------------------------------------------------------

----------
-- __Factory.__ Applies default values to tables.
--
-- @tparam table defaults Mappings key→default_value.
--
-- @treturn function TableNormalizerFunction
-- 
function Table.normalizer (defaults)  
  return function (tbl)
    for k,v in pairs(defaults) do
      if tbl[k] == nil then tbl[k] = v end
      end
    return _toTable(tbl)
    end
  end
  
----------
--  __In-place.__ Applies enclosurized defaults.
-- @tparam table tbl
-- @treturn Table The input table.
-- @function TableNormalizerFunction
-- @usage
--   local my_norm = Table.normalizer{name='no name',value=0}
--   print(my_norm{name='testrr'}:to_string())
--   > {name = "testrr", value = 0}
--   


----------
-- __Factory.__ Moves values from one key to another.
--
-- @tparam table mappings Mappings old\_key→new\_key
-- or old\_key→{new\_key\_1,...,new\_key\_n}
-- @tparam[opt=false] boolean allow_tables_as_keys When this is true then
-- new_key of type table will not be interpreted as a @{DenseArray}
-- of new keys but instead used directly as the key.
--
-- @treturn function TableRemapperFunction
--
function Table.remapper (mappings,allow_tables_as_keys)
  --@future: Allow {old_key_1,...,old_key_n} →　new_key.
  --Currently mapping several olds to one new does not
  --guarantee which old key is preferred but an array
  --could do that.
  if not allow_tables_as_keys then
    -- default case: multiple remappings
    for old,new in pairs(mappings) do
      -- do table check before + outside of remapper function (performance)
      if type(new) ~= 'table' then mappings[old] = {new} end
      end
    return function(tbl)
      for old,new in pairs(mappings) do
        local v = tbl[old]
        if v ~= nil then
          tbl[old] = nil -- delete early to allow re-remapping to old key
          for i=1,#new do tbl[ new[i] ] = v end
          end
        end
      return _toTable(tbl)
      end
  else
    --edge case: tables as keys
    return function(tbl)
      for old,new in pairs(mappings) do
        if tbl[old] ~= nil then
          tbl[new], tbl[old] = tbl[old], nil
          end
        end
      return _toTable(tbl)
      end
    end
  end
  
----------
--  __In-place.__ Applies enclosurized re-mappings.
-- @tparam table tbl
-- @treturn Table The input table.
-- @function TableRemapperFunction
-- @usage
--   -- with multiple remappings per key
--   local my_remapper1 = Table.remapper {name='surname',value={'cur','act'}}
--   local test_person1 = {name='Adicator',value=42}
--   print(my_remapper1(test_person1):to_string())
--   > {act = 42, cur = 42, surname = "Adicator"}
--   
--   -- with tables as keys
--   local my_remapper2 = Table.remapper({name='surname',value={'cur','act'}},true)
--   local test_person2 = {name='Bdicator',value=42}
--   print(my_remapper2(test_person2):to_string())
--   > {[{"cur","act"}] = 42, surname = "Bdicator"}
--

--------------------------------------------------------------------------------
-- Other Methods.
-- @section
--------------------------------------------------------------------------------




  
--------------------------------------------------------------------------------
-- Drafts.     
-- @section
--------------------------------------------------------------------------------




    

  


  
--------------------------------------------------------------------------------
-- Future.
-- @section
--------------------------------------------------------------------------------


-- old stuff of uncertain usability
--[[
  Table.locked_write = function() Error('Table','this table is write-locked.') end
  Table.locked_read  = function() Error('Table','this table is read-locked.' ) end
  Table.singular     = function(x) return (table_size(x)==1) and x[next(x)] or nil end
  --insert but with table return (
  Table.insert       = function(self,key,value) self[key] = value return self end
  ]]
  
  


  
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Table') end
return function() return Table,_Table,_uLocale end
