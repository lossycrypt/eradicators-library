-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @submodule Meta
-- @usage
--  local SwitchCase = require('__eradicators-library__/erlib/lua/Meta/SwitchCase')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local Filter = elreq('erlib/lua/Filter')()


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

-- local SwitchCase,_SwitchCase,_uLocale = {},{},{}


----------
-- Input-dependant handler function switching.
-- A switch case calls one of several functions depending on the output 
-- of a given analyzer function. In case the output of the analyzer does
-- not match any case the `default` case will be returned instead.
-- 
-- @tparam function analyzer The result of analyzer(...) will be used as
-- a key to cases to call `cases\[analyzer\(...\)\]\(...\)`.
-- @tparam table cases A map {key -> function}. Where every possible output
-- of analyzer(...) is represented by a key.
--
--
-- @usage
--    
--    local analyzer = function(x) return type(x) end
--    local cases    = {
--      table   = function(x) return tostring(x[1]) end,
--      number  = function(x) return tostring(x-1 ) end,
--      default = function(x) return          x..2  end,
--      }
--
--    local SC = SwitchCase(analyzer,cases)
--
--    print(SC({42})) --table
--    > 42
--    
--    print(SC(43))   --number
--    > 42
--
--    print(SC('4'))  --default
--    > 42
--
-- @function SwitchCase

local _SwitchCase = function(analyzer,cases)
  Verify('function',analyzer)
  Verify('non_empty_table',cases)
  end
local function SwitchCase (analyzer,cases)
  local default = cases.default or Filter.SKIP
  return function(...)    
    local f = cases[analyzer(...)] or default
    return f(...)
    end
  end



-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.SwitchCase') end
return function() return SwitchCase,_SwitchCase,_uLocale end
