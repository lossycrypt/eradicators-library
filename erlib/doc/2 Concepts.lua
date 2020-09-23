-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

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
-- In contexts where an @{AnyValue} is treated like a @{boolean} it is said
-- to be truthy if it evaluates to true, and falsy if it evaluates to false.
-- In Lua all data types except @{nil} are truthy regardless of their content.
--
-- @name truthy
-- @class field
--
-- @usage if (0 and '' and {}) then print('truthy!') end
--   > truthy!
--
-- @usage if not nil then print('negation of falsy is true!') end
--   > negation of falsy is true!

      
