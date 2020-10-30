-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Some simple filter functions.
--
-- __Status:__ In development.
-- __Compatibility:__ Pure Lua, Factorio
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

local function Set_from_values(tbl)
  local s = {}
  for _,v in pairs(tbl) do s[v] = true end
  return s
  end
    
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
  local not_ok = Set_from_values(sarr)
  return function (obj)
    return not not_ok[obj]
    end
  end
  
  
----------
-- Generates generalized table filter functions.
-- 
-- The TableFilterSpecification must contain either "is" or "has" but not both.
-- 
-- @tparam MixedTable TableFilterSpecification
-- 
-- @tparam string|number TableFilterSpecification.... The DenseArray part
-- of a TableFilterSpecification is a @{Table.TablePath|TablePath}.
-- 
-- @tparam[opt] NotNil|DenseArray TableFilterSpecification.is If this is a
-- DenseArray then the filter will return true if the value at the above given
-- path in the table is equal to any of the values in the array. For convenience
-- if you're only looking for a single target value you can give it directly
-- without putting it in a table.
--
-- @tparam[opt] DenseArray TableFilterSpecification.has Configures the filter
-- to look for values in the subtable found in the filtered object at the given
-- path. The [1] key in this array specifies the comparision mode and must be
-- a literal string 'or','nor','and' or 'nand'.
-- All elements [2] to [n] represent the
-- accepted values in the subtable.
--
-- @treturn function The filter function f(tbl). Calling f with anything that
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
  -- @future: "nor", "nand"?
  -- @future: truthy -> path must simply be truthy (or NotNil?) when no extra mode is given
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
      -- mode keyword 'or' is not ok!
      -- ok = Set.from_values(ok); ok['or'] = nil -- now converted before call.
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
    }
    
  cmps['nor' ] = function(value,ok) return not cmps['or' ](value,ok) end
  cmps['nand'] = function(value,ok) return not cmps['and'](value,ok) end
    
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
  
--------------------------------------------------------------------------------
-- Factory Draft.
-- @section
--------------------------------------------------------------------------------


function Filter.chain(RecursiveFilterChainSpec)

  -- builds a filter from functions
  
  -- thus Filter.table_path only needs to deal with one 
  -- path spec and not recursion.
  
  -- And recursion can be done in Filter.chain which only
  -- has to deal with functions!

  -- Makes the filter a bit more expensive to run
  -- but very powerful (arbitrary functions)
  -- and easy to implement.
  
  local op = {
    ['and'] = function(spec)
      local ok = true
      for i=2,#spec do -- must ignore mode key [1]
        -- V1 allow only functions?
        ok = ok and spec[i](obj)
        -- V2 allow implicit table filters
        ok = ok and Cast(spec[i],'function',Filter.table_filter)(obj)
        if not ok then return false end
        end
      return true
      end,
    
    ['or'] = function()
      end,
    
    }
  
  
  
  local nodespec = {
    'and', --mode: and, or, xand, xor -> lookup table of recursive functions
    
    function()end or table_filter_spec, -- allow in-lining auto-constructing table filters.
    
    }
  
  A = Filter.table_filter {'path','path',is={},has={} }
  return Compose(
    Filter.filter_chain(
    
      {'and',A,B},
      
      
        
      {'or',{'and',A,B},{'and',C,D,E,F}}
      ))
  end
      


  

  
  

function Filter.table_value_draft3(spec)

  -- difference between "is" and "has_or"? -> value vs table

  local op = {
  
    -- value is (equal to) or (superset of) ok
    ['and'] = function(value,ok)
      if type(value) ~= 'table' then return false end
      value = Set.from_values(value)
      
      -- ok[1],ok[#ok] = ok[#ok],nil -- remove the "and" node at pos 1
      
      local r = true
      for i=2,#ok do -- first ok is "and"
        r = r and value[ ok[i] ]
        if not r then return false end
        end
      return true
      end,
      
    -- at least one element of value is also element of ok
    ['or'] = function(value,ok)
      ok = Set.from_values(ok)
      ok['or']=nil
      for _,v in pairs(value) do
        if ok[v] then return true end
        end
      return false
      end,
      
      
    ['is'] = function(value,ok)
      for i=1,#ok do if ok[i] == value then return true end end
      return false
      end,
    }

  
  local mode
  if spec.is and spec.has then err('not both') end
  if not (spec.is or spec.has) then err('wrong mode combo') end
  
  if spec.is then mode = op['is']
    else mode = op[ spec.has[1] ]
    end
  if not mode then err('invalid has mode') end
  
  local ok = Tool.First(spec.is,spec.has)
  
  
  if #spec == 1 and type(ok) ~= 'table' and mode == op['is'] then
    -- The most common case is a paths of length one
    -- compared with a single value. So this deserves special optimization.
    local key = spec[1]
    printl(1)
    return function(obj) return obj[key] == ok end
    
  elseif #spec == 1 then
    printl(2)
    local key = spec[1]
    ok = Table.plural(ok)
    return function(obj) return mode(obj[key],ok) end    
    
  else
    printl(3)
    ok = Table.plural(ok)
    return function(obj) return mode(Table.get(obj,spec),ok) end
      
    
    end

    
  end
      
      
function Filter.table_filter_draft2(filter_spec)


  -- POC but functionally complete
  
  -- test
  
  -- load_erlib(); print(  Filter.table_filter({'a','b','c',is=5,has=5}) ({a={b={c=5}}})  )
  
  -- load_erlib(); print(  Filter.table_filter({'a','b','c',is={5,2},has={1,1,1}}) ({a={b={c=5}}})  )
  
  -- load_erlib(); print(  Filter.table_filter({'a','b','c',is={5,2},has={'or',1,1,1}}) ({a={b={c=5}}})  )
  
  -- is and has are both value ARRAYS
  
  -- "is" means that the obj to test is a non-table
  -- "is" array is tautologically "or" mode
  
  -- "has" means that the obj to test is a table
  -- "has" array ... needs a fucking mode cos it could be "and" or "or" or whatever
  
  local value, has = filter_spec.is, filter_spec.has
  
  if value and has then
    stop('not both at once')
  elseif value then
    if #filter_spec == 0 then
      stop('missing path')
    elseif #filter_spec == 1 then -- short path
      local key = filter_spec[1]
      -- @future: this is probably *the* most frequent case
      -- so load()'ing an optimized version with hardcoded key might be worth it?
      return function(obj) return obj[key] == value end
    elseif #filter_spec > 2 then
      return function(obj) return Table.get(obj,filter_spec) == value end
      end
    
  elseif has then
    local ok = Set.from_values(has)
    if #filter_spec == 0 then
      stop('missing path')
    elseif #filter_spec == 1 then -- short path
      local key = filter_spec[1]
      return function(obj)
        for _,v in pairs(obj[key]) do
          if ok[v] then return true end
          end
        return false
        end
        
    elseif #filter_spec > 2 then
      return function(obj) return not not ok[ Table.get(obj,filter_spec) ] end
      end

  
  else
    stop('missing mode')
    end
 
 
  end

-- return function(obj)      
      
  
----------
-- Creates a table filter function.
function Filter.table_filter_draft1(filter_spec) return function(obj)

  -- OPTIMIZE: one-key-paths can be done by a much less complex function!

  local example = {
    mode='and',
    {'my','path',is ={'value1','value2'}}, -- value exquals exactly
    {'my','path',has={'or','value1','value2'}}, -- value in table
    }
    
  -- local ex2 = {
    -- And = {
      -- f1,
      -- f2,
      -- {Or={ f3,f4 }}
      -- {mode='or',f3,f4 }
      -- }
    -- }
    
    
  local ex2 = { --recursive spec
    'or', 
  
    { 'and',
      {'my','path',is ={'value1','value2'}}, -- value exquals exactly
      {'my','path',has={'or','value1','value2'}}, -- value in table
      {'my','path',is ={'value1','value2'}}, 
      {'my','path',has={mode='and','value1','value2'}},
      {'my','path',has={mode='or' ,'value1','value2'}},
      },
    
    { 'and',
      {'my','path',is ={'value1','value2'}}, -- value exquals exactly
      {'my','path',has={'or','value1','value2'}}, -- value in table
      },
  
  
    }

  -- local ex3 = Chain {
    -- 'and',
    -- {'or',
      -- {'path',is=5},
      -- {'path',is=6},
      -- {'path',is=7},
      -- },
    -- {'and'},
      -- {'path',has=
    
    -- }
    

  return nil
  end end
   


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Filter') end
return function() return Filter,_Filter,_uLocale end