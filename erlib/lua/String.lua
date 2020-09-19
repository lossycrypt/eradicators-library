-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @module String
-- @usage
--  local String = require('__eradicators-library__/erlib/factorio/String')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag = table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local String,_String,_uLocale = {},{},{}


--------------------------------------------------------------------------------
-- Section
-- @section
--------------------------------------------------------------------------------

----------
-- Foo
-- @table Foo
-- @usage


----------
-- Puts a seperator between every $pattern of the input string.
function String.splice(str,pattern,length,seperator)
  seperator = seperator or ','
  pattern = pattern or '.'
  i = length or #str
  return str
    :sub(1,i)                  --partial string
    :gsub(pattern,'%1'..seperator) --comma seperate
    :sub(1,-2)                 --no comma after last
  end



-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.String') end
return function() return String,_String,_uLocale end
