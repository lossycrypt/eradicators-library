-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Some simple filter functions.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Polishing.
-- @{Introduction.Compatibility|Compatibility}: Pure Lua.
--
-- @module Filter
-- @usage
--  local Filter = require('__eradicators-library__/erlib/lua/Filter')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --

local Verify     = elreq('erlib/lua/Verificate')().verify
    
local log        = elreq('erlib/lua/Log'  )().Logger  'Filter'
local stop       = elreq('erlib/lua/Error')().Stopper 'Filter'

local Table      = elreq('erlib/lua/Table'     )()
local Array      = elreq('erlib/lua/Array'     )()
local Set        = elreq('erlib/lua/Set'       )()

local Logic      = elreq('erlib/lua/Logic'     )()
local Tool       = elreq('erlib/lua/Tool'      )()
local L          = elreq('erlib/lua/Lambda'    )()

local Table_get
    = Table.get

local string_find, string_sub
    = string.find, string.sub
    
-- -------------------------------------------------------------------------- --
-- Dependency Avoidance                                                       --
-- -------------------------------------------------------------------------- --

-- Keep Filter reasonably light-weight and simple?

-- Set->Table->String->Meta->SwitchCase
-- local Set = elreq('erlib/lua/Set')()

-- local function Set_from_values(tbl)
  -- local s = {}
  -- for _,v in pairs(tbl) do s[v] = true end
  -- return s
  -- end
    
-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Filter = {}

--------------------------------------------------------------------------------
-- Simple.
-- @section
--------------------------------------------------------------------------------

----------
-- No-Op, does nothing at all.
Filter.SKIP  = ercfg.SKIP

----------
-- Always returns boolean true.
Filter.TRUE  = function( ) return true end

----------
-- Always returns boolean false.
Filter.FALSE = function( ) return false end

----------
-- Returns obj.valid, the validity of factorio LuaObjects.
-- @tparam LuaObject obj
-- @usage 
--    for k,entity in Iter.filtered_pairs(entities,Filter.VALID) do
--      print(entity.name,'is valid!')
--      end
Filter.VALID = function(obj) return not not obj.valid end

----------
-- Returns true for factorio LuaObjects that are __not__ valid.
-- @tparam LuaObject obj
-- @usage 
--    for k,entity in Iter.filtered_pairs(entities,Filter.INVALID) do
--      print(k,'is not valid anymore!')
--      end
Filter.INVALID = function(obj) return not obj.valid end


----------
-- Returns the object given. For when the syntax requires a function but
-- you don't want to actually change the object.
-- @tparam AnyValue obj
-- @treturn AnyValue obj
Filter.PASS = function(obj) return obj end



--------------------------------------------------------------------------------
-- Factory.
-- @section
--------------------------------------------------------------------------------

----------
-- @tparam string prefix The exact plain prefix to look for. Not a lua pattern.
-- 
-- @treturn function The filter function f(str) returns true if __str starts with__
-- the prefix.
-- 
function Filter.string_prefix(prefix)
  local n = #prefix
  return function(str)
    return string_sub(str,1,n) == prefix
    end
  end
  

----------
-- @tparam string postfix The exact plain postfix to look for. Not a lua pattern.
-- 
-- @treturn function The filter function f(str) returns true if __str ends with__
-- the postfix.
-- 
function Filter.string_postfix(postfix)
  local n = #postfix
  return function(str)
    return string_sub(str,-n) == postfix
    end
  end
  
  
----------
-- @tparam string infix The exact plain infix to look for. Not a lua pattern.
-- 
-- @treturn function The filter function f(str) returns true if __str contains__
-- the infix.
-- 
function Filter.string_infix(infix)
  return function(str)
    return not not string_find(str,infix,1,true) -- plain
    end
  end
  
----------
-- @tparam string pattern A lua string @{Pattern}.
-- @tparam[opt=1] NaturalNumber init The position at which to start the search
--
-- @treturn function The filter function f(str) returns true if the pattern
-- matches the string.
-- 
function Filter.string_pattern(pattern, init)
  init = init or 1
  return function(str)
    return not not string_find(str, pattern, init)
    end
  end
  
----------
-- Whitelist / Allowlist.
-- 
-- @tparam SparseArray sarr A list of objects that should return @{true} when
-- passed to the filter. All other objects will return @{false}.
-- 
-- @treturn function The filter function f(obj) returns a @{boolean}.
-- 
function Filter.true_object_array(sarr)
  local ok = Set.from_values(sarr)
  return function (obj)
    return not not ok[obj]
    end
  end
  
  

----------
-- Blacklist / Blocklist.
-- 
-- @tparam SparseArray sarr A list of objects that should return @{false} when
-- passed to the filter. All other objects will return @{true}.
-- 
-- @treturn function The filter function f(obj) returns a @{boolean}.
-- 
function Filter.false_object_array(sarr)
  local not_ok = Set.from_values(sarr)
  return function (obj)
    return not not_ok[obj]
    end
  end
  
  
----------
-- Generates generalized table filter functions.
-- 
-- The TableValueFilterSpecification must contain either "is" or "has" but not both.
-- 
-- @tparam MixedTable TableValueFilterSpecification
-- 
-- @tparam string|number TableValueFilterSpecification.... The DenseArray part
-- of a TableValueFilterSpecification is a @{Table.TablePath|TablePath}.
-- 
-- @tparam[opt] NotNil|DenseArray TableValueFilterSpecification.is If this is a
-- DenseArray then the filter will return true if the value at the above given
-- path in the table is equal to any of the values in the array. For convenience
-- if you're only looking for a single target value you can give it directly
-- without putting it in a table.
--
-- @tparam[opt] DenseArray TableValueFilterSpecification.has Configures the filter
-- to look for values in the subtable found in the filtered object at the given
-- path. The [1] key in this array specifies the comparision mode and must be
-- a literal string 'or','nor','and' or 'nand'.
-- All elements [2] to [n] represent the
-- accepted values in the subtable. When no accepted values are given
-- 'and' is always true and 'or' is always false.
--
-- @treturn function The TableValueFilter function f(tbl). Calling f with anything that
-- is not a table will always return false.
--
-- @usage
--   local tblA = {keyA = {keyB = {1,2,3,4}, keyC = 1}}
--   local tblB = {keyA = {keyB = {3,4,5,6}}}
--
--   -- "is" is an exact comparision
--   print(Filter.table_value {'keyA','keyB',is  =  1         } (tblA) )
--   > false
--   print(Filter.table_value {'keyA','keyC',is  =  1         } (tblA) )
--   > true
--
--   -- "and" must have all elements given
--   print(Filter.table_value {'keyA','keyB',has = {'and',1,2}} (tblA) )
--   > true
--   print(Filter.table_value {'keyA','keyB',has = {'and',2,3}} (tblB) )
--   > false
--
--   -- "or" needs only one element
--   print(Filter.table_value {'keyA','keyB',has = {'or' ,1,6}} (tblA) )
--   > true
--   print(Filter.table_value {'keyA','keyB',has = {'or' ,1,6}} (tblB) )
--   > true
-- 
-- @function Filter.table_value
do
  
  --@future: "NotNil" -> no specific value, Just *any* value.
  -- by specifying neither .is not .has? What about "truthy"?

  local cmps = {
    -- equal(value,ok) or superset(value,ok)
    ['and'] = function(value,ok)
      if type(value) ~= 'table' then return false end
      value = Set.from_values(value)
      local r = true
      for i=2,#ok do -- first ok is "and"
        r = r and value[ ok[i] ]
        if not r then return false end
        end
      return true
      end,
    -- at least one element of value is also an element of ok
    ['or'] = function(value,ok)
      if type(value) ~= 'table' then return false end
      for _,v in pairs(value) do
        if ok[v] then return true end
        end
      return false
      end,
    -- value is equal to any element of ok
    ['is'] = function(value,ok)
      for i=1,#ok do if ok[i] == value then return true end end
      return false
      end,
      
      
    -- EXPERIMENTAL -> Tomorrow!
    -- only works for tables not .is values
    -- actually *does* work for the ".is" *concept*
    -- just that it needs a .has={'truthy'} style spec.
    -- which breaks the ".has means table" rule.
    --> But putting it in real .is collides with
    -- user input when they actually *want* the litteral strings
    -- and not the mode.
    ['truthy'] = function(value)
      if value then return true else return false end
      end,
    ['NotNil'] = function(value)
      return value ~= nil
      end,
      
      
    }
  cmps['nor' ] = function(value,ok) return not cmps['or' ](value,ok) end
  cmps['nand'] = function(value,ok) return not cmps['and'](value,ok) end
  -- these comparators need the ok-table to be
  -- pre-converted to a Set and the mode keyword removed.
  local okToSet = { ['or'] = true, ['nor'] = true }
    
function Filter.table_value(spec)
  local I, H = (spec.is ~= nil), (spec.has ~= nil)
  Verify(Logic.Xor(I, H), 'true', 'Spec must have either .is or .has:\n', spec)
  -- 
  local ok = Tool.First(spec.is, spec.has)
  local mode = I and 'is' or spec.has[1]
  local _cmp = cmps[mode]
  Verify(_cmp, 'func', 'Unknown comparison mode:\n', spec)
  -- Main usecase: 1-length-paths compared to a single value.
  if #spec == 1 and type(ok) ~= 'table' and mode == 'is' then
    local ok, key = ok, spec[1]
    return function(obj)
      if type(obj) ~= 'table' then return false end
      return obj[key] == ok end
  -- Generic 1-length-paths doesn't need slow Table.get()
  elseif #spec == 1 then
    local ok, key = Table.plural(ok), spec[1]
    if okToSet[mode] then ok = Set.from_values(ok); ok[mode] = nil end
    return function(obj)
      if type(obj) ~= 'table' then return false end
      return _cmp(obj[key], ok) end    
  -- Generic n-length path
  else
    local ok, path = Table.plural(ok), Array.scopy(spec)
    if okToSet[mode] then ok = Set.from_values(ok); ok[mode] = nil end
    return function(obj)
      if type(obj) ~= 'table' then return false end
      return _cmp(Table_get(obj,path),ok) end
    end
  end
  end
  

----------
-- Composes multiple filters into one.
-- 
-- @tparam DenseArray RecursiveFilterChainSpecification
-- @tparam string RecursiveFilterChainSpecification.1
-- How the filters should be combined. Must be one of the
-- literal combination mode strings "and", "nand", "or" or "nor".
-- @tparam table|function RecursiveFilterChainSpecification....
-- The filters to be combined. Each value can be either a custom filter
-- function f(obj), a @{Filter.table_value|TableValueFilterSpecification}
-- or another RecursiveFilterChainSpecification.
-- 
-- __Note:__ The first path key in an in-line TableValueFilterSpecification
-- can not be a filter chain combination mode string ("and", "or", etc.).
-- Cou have to pre-compile the TableValueFilter in that case.
-- 
-- @usage
--   local f = Filter.chain { -- RecursiveFilterChainSpecification
--     'or',
--     function(x) return (type(x) == 'number') and (x > 5) end, -- custom function
--     { -- another RecursiveFilterChainSpecification
--       'and',
--       {'number', is ={5,42} },                   -- TableValueFilterSpecification
--       {'names' , has={'or','Michiko','Tarou'} }, -- TableValueFilterSpecification
--       }
--     }
--   print( f(5) ) -- not x > 5
--   > false
--   print( f(6) ) -- x > 5
--   > true
--   print( f{number = 5 , names = {'Mamoru' } } ) -- wrong name
--   > false
--   print( f{number = 42, names = {'Michiko'} } ) -- number and name ok
--   > true
--
-- @function Filter.chain
do
  --load_erlib(); Filter.chain{'or',function(x) return x > 5 end, function(x) return x <2 end}
  --load_erlib(); print( Filter.chain{'or', {'a',is=5}, {'and',{'b',is=7},{'c',is=7}} } (7))
  --load_erlib(); print( Filter.chain{'or', {'a',is=5}, {'and',{'b',is=7},{'c',has={'and',6,5}}} } ({a=4,b=7,c={5,3,6}}))
  local cmps = {
    -- @future: xand, xor?
    ['or'] = function(_spec) return function(obj)
      for i=1,#_spec do
        if _spec[i](obj) then return true end
        end
      return false
      end end,
    ['and'] = function(_spec) return function(obj)
      local ok = true
      for i=1,#_spec do 
        ok = ok and _spec[i](obj)
        if not ok then return false end
        end
      return true
      end end,
    }
  cmps['nor' ] = function(_spec) return L('x->not A(x)',cmps['or '](_spec)) end
  cmps['nand'] = function(_spec) return L('x->not A(x)',cmps['and'](_spec)) end
  
function Filter.chain(user_spec)
  -- resurses into the spec and composes a tree function
  local function _norm(spec)
    -- user-supplied filter
    if type(spec) == 'function' then
      return spec
    -- only tables and functions allowed
    elseif type(spec) ~= 'table' then
      stop('Not a valid RecursiveFilterChainSpec:\n',spec)
    -- TableValueFilterSpec or RecursiveFilterChainSpec
    elseif type(spec) == 'table' then
      -- Is this a known comparator mode?
      local cmp = cmps[ spec[1] ]
      -- No. -> Assume in-line TableValueFilterSpec
      if cmp == nil then
        return Filter.table_value(spec)
      -- Yes. -> RecursiveFilterChainSpec
      else
        -- remove mode keyword and convert to functions
        return cmp(Array.map(spec, L('s,i->A(s),i-1', _norm), {}, 2))
        end
      end
    end
  return _norm(user_spec)
  end
  end

  
  
--------------------------------------------------------------------------------
-- Factory Draft.
-- @section
--------------------------------------------------------------------------------

  
   


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Filter') end
return function() return Filter, nil, nil end