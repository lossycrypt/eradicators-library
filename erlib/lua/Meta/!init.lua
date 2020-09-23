-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Produce function wrappers from other functions.
--
-- @module Meta
-- @usage
--  local Meta = require('__eradicators-library__/erlib/lua/Meta/!init')()
  
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

local Meta,_Meta,_uLocale = {},{},{}



Meta.Compose   = elreq('erlib/lua/Meta/Compose')()
Meta.Closurize = elreq('erlib/lua/Meta/Closurize')()
Meta.Memoize   = elreq('erlib/lua/Meta/Memoize')()
Meta.SwitchCase = elreq('erlib/lua/Meta/SwitchCase')()


-- -----------------------------------------------------------------------------
-- Section
-- @section
-- -----------------------------------------------------------------------------

-- -------
-- Nothing.
-- @within Todo
-- @field todo1

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Meta') end
return function() return Meta,_Meta,_uLocale end
