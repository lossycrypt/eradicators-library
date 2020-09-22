-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Specialized iteration of tables and other objects.
--
-- @module Iter
-- @usage
--  local Iter = require('__eradicators-library__/erlib/factorio/Iter')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local import = function(path) return (require(elroot..path))() end --unpacking


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Iter,_Iter,_uLocale = {},{},{}



Iter.deep_pairs = import('erlib/lua/Iter/deep_pairs')






--------------------------------------------------------------------------------
-- Section
-- @section
--------------------------------------------------------------------------------


----------
-- Find out how to make LDoc obey custom names for
-- sections and iterators.
-- @within Todo
-- @field todo-1

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Iter') end
return function() return Iter,_Iter,_uLocale end
