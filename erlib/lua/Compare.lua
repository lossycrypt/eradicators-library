-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Polishing.
--
-- @module Compare
-- @usage
--  local Compare = require('__eradicators-library__/erlib/lua/Compare')()

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

local Compare,_Compare,_uLocale = {},{},{}


--------------------------------------------------------------------------------
-- Section.
-- @section
--------------------------------------------------------------------------------

-- -------
-- Nothing.
-- @within Todo
-- @field todo1


----------
-- True if a is shorter than b.
-- Equal length strings are sorted alphabetically.
--
-- @tparam string a
-- @tparam string b
--
-- @treturn boolean
--
-- @usage
--   print(Array.sort({'ababa','aaaa','aab'},Compare.STRING_SHORTER):to_string())
--   > {"aab", "aaaa", "ababa"}
--
function Compare.STRING_SHORTER (a,b)
  if #a == #b then
    return a < b --alphabetic for same length
  else
    return #a < #b
    end
  end

  
----------
-- True if a is before b in natural language order.
--
-- @tparam string a
-- @tparam string b
--
-- @treturn boolean
--
-- @usage
--   print(Array.sort({'aaaa','aab','ababa'},Compare.STRING_ALPHABETIC):to_string())
--   > {"aaaa", "aab", "ababa"}
--
function Compare.STRING_ALPHABETIC(a,b)
  return a < b
  end




-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Compare') end
return function() return Compare,_Compare,_uLocale end
