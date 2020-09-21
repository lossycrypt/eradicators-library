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
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

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

  
  
----------
-- __PROOF OF CONCEPT__. __SLOW__. Do not use in production.   
-- Python-esque string formatting from locals and upvalues.
-- @tparam string str the formatting pattern
-- @within Experimental
-- @usage
--   local f = String._poc_format
--   function test(name,surname)
--     print(f'Hi. My name is {name} {surname}!')
--     end
--   test('E.R.','Adicator')
--   > Hi. My name is E.R. Adicator!
function String._poc_format(str)
  -- [1] http://lua-users.org/lists/lua-l/2004-01/msg00075.html
  -- Identifiers in Lua can be any string of letters, digits, and
  -- underscores, not beginning with a digit.  
  local caller = debug.getinfo(2,'f').func
  local values = {} 
  --upvalues
  local i=0; while true do i=i+1
    local k,v = debug.getupvalue(caller,i)
    if k == nil then break end
    values[k]=v
    end
  --locals (overshadow upvalues)
  local i=0; while true do i=i+1
    local k,v = debug.getlocal(2,i)
    if k == nil then break end
    values[k]=v
    end
  --string replace one-by-one
  --@todo: can this be streamlined into a single call for :format?
  for match,key,tail in string.gmatch(str,'({([_%a][_%w]*):?(.-)})') do
    local value = values[key]
    if tail == '' then tail = 's' end -- singular % is not valid format string
    str = str:gsub(match,'%%'..tail):format(value) -- nil becomes "nil"
    end  
  return str
  end


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.String') end
return function() return String,_String,_uLocale end
