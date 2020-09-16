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
      
