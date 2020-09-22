-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
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
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

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


--------------------------------------------------------------------------------
-- Section
-- @section
--------------------------------------------------------------------------------

----------
-- Nothing.
-- @within Todo
-- @field todo1

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Set') end
return function() return Set,_Set,_uLocale end
