-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Some simple filter functions.
--
-- @module Filter
-- @usage
--  local Filter = require('__eradicators-library__.erlib.lua.Filter')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --

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

-- Filter.SKIP  = function( ) end

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
-- Creates a table filter function.
function Filter.new_complex(filter_spec) return function(obj)

  local example = {
    'and',
    {'my','path',is ={'value1','value2'}}, -- value exquals exactly
    {'my','path',has={'or','value1','value2'}}, -- value in table
    }
    
  local ex2 = { --recursive spec
    'or', 
  
    { 'and',
      {'my','path',is ={'value1','value2'}}, -- value exquals exactly
      {'my','path',has={'or','value1','value2'}}, -- value in table
      },
    
    { 'and',
      {'my','path',is ={'value1','value2'}}, -- value exquals exactly
      {'my','path',has={'or','value1','value2'}}, -- value in table
      },
  
  
    }


  return nil
  end end
   


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Filter') end
return function() return Filter,_Filter,_uLocale end