-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Abstract programming and behavioral concepts used by the library.
--
-- @module Concepts
-- @set all=true
-- @set sort=false


--------------------------------------------------------------------------------
-- Concepts
-- @section
--------------------------------------------------------------------------------


----------
-- When an environment variable _ENV.STDOUT is truthy then any compatible
-- function will call STDOUT(...) instead of log(...). If a function is
-- compatible is mentioned in each functions description.
--
-- @name STDOUT
-- @class field
--
-- @usage _ENV.STDOUT = _ENV.print
            
----------
-- Every Lua @{table} maps keys to values.
-- @name key
-- @class field
-- @usage local my_table = {key = 'value'}

----------
-- Every Lua @{table} maps keys to values.
-- @name value
-- @class field
-- @usage local my_table = {['key'] = value}
