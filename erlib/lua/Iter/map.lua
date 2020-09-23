-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @submodule Iter
-- @usage
--  local map = require('__eradicators-library__/erlib/lua/Iter/map')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))



-- [1] file:///H:/docs/python-docs/3.8.5/library/functions.html#map
  
-- multi_map?

-- Iterator over several tables at once.
-- first iteratable determines key order and length (different to python)

-- fetch next=pairs(obj) and closurize into iter
  

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Iter.map') end
return function() return map end
