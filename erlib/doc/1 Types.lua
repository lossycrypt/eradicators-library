-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- A general overview over the (custom) data types used throughout this documentation.
--
-- @module Types
-- @set all=true
-- @set sort=false


--------------------------------------------------------------------------------
-- Tables.
-- @section
--------------------------------------------------------------------------------


----------
-- Every Lua table maps @{NotNil} keys to NotNil values.
-- Every specialized table can also be used as a standard Table.
--
-- @field key @{NotNil}
-- @table Table
--
-- @usage
--   local Table = {key = value}

  
----------
-- A @{wiki Set_(mathematics)} is a table in which all values are @{true} and
-- the keys are the actual values. This is useful to quickly test if a given key
-- is in a Set or not.
--
-- @field key @{true}
-- @table Set
--
-- @usage
--   local Set = {}
--   for _,value in pairs(Table) do
--     Set[value] = true
--     end
-- @usage if Set[key] then f() end
-- @usage for value,_ in pairs(Set) do print(value) end


----------
-- An Array - sometimes also called a DenseArray - is a table
-- in which all keys are non-zero @{NaturalNumber}s. Additionally
-- the sequence of numbers must be uninterrupted - for every
-- key n in the array there must also be a key n-1, except for n=1 which
-- must be the first key (or the Array is empty).
--
-- Arrays are the ONLY type of Table for which the Lua length operator #
-- reports the correct number of elements. For all other types of Table
-- @{FAPI Libraries table_size}() must be used.
--
-- @field 1 @{NotNil}
-- @field 2 @{NotNil}
-- @field 3 @{NotNil}
-- @table Array
--
-- @usage
--   for i=1,#Array do print(Array[i]) end
--
-- @usage
--   local A = {'a','b','c','d','e'}
--   print(#A)
--   > 5


----------
-- A SparseArray is also a @{Table} in which all keys are @{NaturalNumber}s.
-- Contrary to an @{Array} the sequence of keys may be discontinuous.
--
-- These are often used to store entities indexed by their unit_number.
--
-- @field 1  @{NotNil}
-- @field 5  @{NotNil}
-- @field 42 @{NotNil}
-- @table SparseArray
--
-- @usage
--  local entities = {[entity.unit_number] = entity}

  
--------------------------------------------------------------------------------
-- Numbers
-- @section
--------------------------------------------------------------------------------


----------
-- The basic Lua type for numbers. It can be any @{Integer} or @{float}.
--
-- @name Number
-- @class field


----------
-- A @{number} that has a non-zero decimal fraction.
--
-- @name float
-- @class field
--
-- @usage local float = 3.14159


----------
-- A @{number} that does not have a decimal fraction.
--
-- @name Integer
-- @class field
--
-- @usage local Integer = 42
  
  
----------
-- An @{Integer} >= 0. Also called a PositiveInteger.
--
-- @name NaturalNumber
-- @class field


----------
-- An @{Integer} < 0.
--
-- @name NegativeInteger
-- @class field


--------------------------------------------------------------------------------
-- Boolean
-- @section
--------------------------------------------------------------------------------


----------
-- A @{boolean} that is always true, never false.
--
-- @name true
-- @class field


--------------------------------------------------------------------------------
-- Misc
-- @section
--------------------------------------------------------------------------------


----------
-- Any string, @{number}, boolean, @{table}, function or userdata.
--
-- @name NotNil
-- @class field

----------
-- Any string, @{number}, boolean, @{table}, function, userdata or nil.
--
-- @name AnyValue
-- @class field

----------
-- Any value that when negated twice evaluates to @{true}. In Lua this is
-- any string, @{number}, @{true}, @{table}, function or userdata. But not
-- boolean false or nil.
--
-- @name TruthyValue
-- @class field
--
-- @usage local yes = ((not not TruthyValue) == true)
-- @usage local yes = (TruthyValue and true)


--------------------------------------------------------------------------------
-- Load Stage / Phase
-- @section
--------------------------------------------------------------------------------


----------
-- The name of a load stage.
-- One of three strings: "settings", "data" or "control".
--
-- @name LoadStageName
-- @class field


----------
-- The name of a load phase.
-- This is one of 7 strings:
--   "settings", "settings_updates", "settings_final_fixes"
--   "data", "data_updates", "data_final_fixes"
--   or "control".
--
-- Be aware that unlike the corresponding file names these strings
-- use _ underscores instead of - dashes for ease of use.
--
-- @name LoadPhaseName
-- @class field


----------
-- A @{Table} that contains three keys->value mappings. It is used
-- for stage based conditional code execution.
--
-- @field LoadStageName @{true}, maps  @{LoadStageName} → @{true}
-- @field any           @{true}, maps of the string "any" → @{true}
-- @field name          string, the @{LoadStageName}
-- @table LoadStageTable
--
-- @usage
--    if LoadStageTable.control then
--      script.on_event(defines.events.on_tick,function()end)
--      end


----------
-- A @{Table} that contains three (key → value) mappings.
--
-- @field LoadPhaseName @{true}
-- @field name          @{LoadPhaseName}
-- @field any           @{true}
-- @table LoadPhaseTable
