-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Manipulates key->value Sets. All functions in this module also work on 
-- @{PseudoSet}s. For further info read @{wiki Set_(mathematics)|Wikipadia on Sets}
-- and @{wiki List_of_logic_symbols}. In unions and intersections of PseudoSets
-- the values of Set B take precedence.
--
-- __Note:__ This module inherits all @{Table} module methods.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Stable.
--
-- @module Set
-- @usage
--  local Set = require('__eradicators-library__/erlib/lua/Set')()
  
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

local setmetatable, getmetatable
    = setmetatable, getmetatable
    
local Table_size
    = Table.size

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Set,_Set,_uLocale = {},{},{}


--@todo: Consider the pros and cons of using "~=nil" instead of "==true" 
--       for ALL operations.

-- Pro:
--   + Easy use of Set.* operations on tables that store a useful value.
--     ? Possibly reduced data storage because copying is not needed
--     ? Possibly *increased* data storage by keeping outdated references.
--   + No need to convert dictionaries. Only arrays need conversion.

-- Contra:
--   - Ambigious situations might arise in other peoples code.
--     ? Providing a Set.enforce_true could remedy this.

-- Best:
--   + Mixed approach. 
--   + By default values are "true" but user can chose to keep real values.
--   + The module itself always uses ~= nil so it doesn't care either way.


-- -------------------------------------------------------------------------- --
-- Metatable                                                                  --
-- -------------------------------------------------------------------------- --

-- Inherit all Table methods.
for k,v in pairs( Table) do  Set[k] = v end
for k,v in pairs(_Table) do _Set[k] = v end

local _obj_mt = {__index=Set}
-- attach meta if safe
-- local _toSet = function(tbl)
  -- if not getmetatable(tbl) then setmetatable(tbl,_obj_mt) end
  -- return tbl end
-- force attach meta
local _toSet = function(tbl, A, keep_meta)
  if  (keep_meta ~= false)
  and (getmetatable(A) == _obj_mt)
    then return setmetatable(tbl, _obj_mt)
    else return tbl end
  end
  
-- user request to attach meta unconditionally
do setmetatable( Set,{__call = function(_,tbl) return setmetatable(tbl,_obj_mt) end}) end
do setmetatable(_Set,{__call = function(_,tbl) return setmetatable(tbl,_obj_mt) end}) end

--------------------------------------------------------------------------------
-- Module.
-- @section
--------------------------------------------------------------------------------

-- -------
-- Nothing.
-- @within Todo
-- @field todo1


----------
-- Attaches this Set module as metatable to a table.  
-- Alias for `setmetatable(set, {__index = Set})`.
--
-- @tparam table set
-- @treturn PseudoSet The unchanged input table, now with metatable attached.
-- @function Set
do end


--------------------------------------------------------------------------------
-- Conversion
-- @section
--------------------------------------------------------------------------------


----------
-- Creates a @{Set} that maps all values from the input table to @{true}.
-- @tparam table tbl
-- @treturn set
function Set.from_values(tbl)
  local s = {}
  for _,v in pairs(tbl) do s[v] = true end
  -- return _toSet(s) end
  return s end

----------
-- Creates a @{Set} that maps all keys from the input table to @{true} 
-- @tparam table tbl
-- @treturn set
function Set.from_keys(tbl)
  local s = {}
  for k   in pairs(tbl) do s[k] = true end
  -- return _toSet(s) end
  return s end

--------------------------------------------------------------------------------
-- Creation.
--
-- For all of these functions: If the input set `A` had the module metatable
-- attached by calling `Set(A)` then the resulting set will automatically
-- inherit the metatable. This behavior can be disabled by passing @{false}
-- as a third parameter. Any metatable not created by `Set()` will never be
-- inherited.
--
-- @section
--------------------------------------------------------------------------------

  
  
--- →∀x (Ax ∨ Bx)
-- @treturn set
function Set.union(A, B, keep_meta)
  local s = {}
  for k,v in pairs(A) do s[k]=v end
  for k,v in pairs(B) do s[k]=v end
  return _toSet(s, A, keep_meta) end

--- →∀x (Ax ∧ Bx)
-- @treturn set
function Set.intersection(A, B, keep_meta)
  local s = {}
  for k,v in pairs(B) do
    if A[k] ~= nil then s[k]=v end
    end
  return _toSet(s, A, keep_meta) end
  
--- →∀x (Ax ∧ ¬Bx)  
-- @treturn set
function Set.complement(A, B, keep_meta)
  local s = {}
  for k,v in pairs(A) do
    if B[k] == nil then s[k]=v end
    end
  return _toSet(s, A, keep_meta) end
  
--- →∀x (¬(Ax ∧ Bx))    
-- @treturn set
function Set.difference(A, B, keep_meta)
  return _toSet(Set.union(
    Set.complement(A, B, false),
    Set.complement(B, A, false)
    ), A, keep_meta)
  end

--------------------------------------------------------------------------------
-- Comparison
-- @section
--------------------------------------------------------------------------------

  
--- →∃e (Ae)
-- @treturn boolean
function Set.contains(A,e)
  return A[e] ~= nil end
  
--- A⊃B, ∀xBx (Ax) ∧ ∃xAx (¬Bx)
-- @treturn boolean
function Set.is_superset(A,B)
  for k in pairs(B) do if A[k] == nil then return false end end
  for k in pairs(A) do if B[k] == nil then return true  end end
  return false end -- A==B

--- A⊂B, ∀xAx (Bx) ∧ ∃xBx (¬Ax)
-- @treturn boolean
function Set.is_subset(A,B)
  return Set.is_superset(B,A) end
  
--- A⇔B, ∀xAx (Bx) ∧ ∀xBx (Ax)
-- @treturn boolean
function Set.is_equal(A,B)
  for k in pairs(B) do if A[k] == nil then return false end end
  for k in pairs(A) do if B[k] == nil then return false end end
  return true end

--- A∩B==∅, ¬∃xAx (Bx) ∧ ¬∃xBx (Ax), ∀xAx (¬Bx) ∧ ∀xBx (¬Ax).    
-- The empty set is disjoint from every set, including from itself.
-- @treturn boolean
function Set.is_disjoint(A,B)
  if Table_size(A) == 0 or Table_size(B) == 0 then return true end
  for k in pairs(A) do if B[k] ~= nil then return false end end
  for k in pairs(B) do if A[k] ~= nil then return false end end
  return true end
  
  
--------------------------------------------------------------------------------
-- Metamethods  
-- @section
--------------------------------------------------------------------------------

-- Concatenation with `\.\.` is Set.union().
-- @function Set.__concat
-- _obj_mt.__concat = Set.union

--- Addition with + is Set.union().
-- @function Set.__add
_obj_mt.__add    = Set.union

--- Substraction with - is Set.complement().
-- @function Set.__sub
_obj_mt.__sub    = Set.complement


  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Set') end
return function() return Set,_Set,_uLocale end
