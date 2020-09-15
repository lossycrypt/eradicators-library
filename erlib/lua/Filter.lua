-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Some simple filter functions.
--
-- @module Filter
-- @usage
--  local Filter = require('__eradicators-library__.erlib.lua.Filter')()
  
  

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Filter = {}


----------
-- No-Op, does nothing at all.
Filter.SKIP  = function( ) end

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

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
return function() return Template,_Template,_uLocale end