-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- A bunch of small utilities. Factorio already has "util" so this is Tool.
-- Basically a collection of functions that don't fit into any other module.
-- When a new module is added that is a good fit for one of these they
-- will be moved there on short notice so watch the changelog carefully.
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

local stop = elreq('erlib/lua/Error')().Stopper('Tool')

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
-- @usage local prototype = Tool.apply(SimpleHotkey,{'some','values'})
function Tool.apply(f,o) return o,f(o) end
 
----------
-- Get the first non-nil value.
-- For when you can't use `return a or b` because false is a valid return value.
--
-- @tparam AnyValue ... It is an error if not at least one value given is @{NotNil}.
-- @treturn NotNil The first value that was not nil. Can return boolean false
-- if that was the first applicable value.
function Tool.first(...)
  local args,n = {...},select('#',...)
  for i=1,n do
    if args[i] ~= nil then return args[i] end
    end
  stop('Tool.first','All given values were nil!') -- really useful?
  end
 
 
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Tool') end
return function() return Tool,_Tool,_uLocale end
