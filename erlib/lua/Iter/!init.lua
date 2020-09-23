-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Specialized iteration of tables and other objects.
-- 
-- "pairs" methods take a single input table.
-- "touples" methods take an arbitrary number of tables.
-- 
-- @module Iter
-- @usage
--  local Iter = require('__eradicators-library__/erlib/lua/Iter')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
-- local import = function(path) return (require(elroot..path))() end --unpacking


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Iter,_Iter,_uLocale = {},{},{}



Iter.deep_pairs  = elreq('erlib/lua/Iter/deep_pairs' )()
Iter.sync_tuples = elreq('erlib/lua/Iter/sync_tuples')()
Iter.filter_pairs  = elreq('erlib/lua/Iter/filter_pairs' )()
-- Iter.map_tuples  = elreq('erlib/lua/Iter/map_tuples' )()

-- Iter.map_tuples is trivial to emulate with sync_tuples so
-- no extra module is required.
--
-- for k,v1,v2,v3 in sync_tuples(t1,t2,t3,t4) do
--   local result = f(v1,v2,v3)
--   DoStuff()
--   end






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
