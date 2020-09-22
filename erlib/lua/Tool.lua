-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- A bunch of small utilities. Factorio already has "util" so this is Tool.
--
-- @module Tool
-- @usage
--  local Tool = require('__eradicators-library__/erlib/factorio/Tool')()
  
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

local Tool,_Tool,_uLocale = {},{},{}



--------------------------------------------------------------------------------
-- Section
-- @section
--------------------------------------------------------------------------------

----------
-- In-Line definition and simultaenous usage of new tables.
-- @tparam function f
-- @tparam AnyValue o
-- @usage local prototype = Tool.fetch(SimpleHotkey,{'some','values'})
function Tool.fetch(f,o) return o,f(o) end
 
 
 
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Tool') end
return function() return Tool,_Tool,_uLocale end
