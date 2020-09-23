-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
--  
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
local type = type

local real_tostring = _ENV.tostring

local Hydra    = elreq ('erlib/lua/Coding/Hydra')()
local Meta     = elreq ('erlib/lua/Meta/!init')()


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local String,_String,_uLocale = {},{},{}


--------------------------------------------------------------------------------
-- Section
-- @section
--------------------------------------------------------------------------------

String.UPPER_LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
String.UPPER_ARGS    = 'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z'
String.LOWER_LETTERS = 'abcdefghijklmnopqrstuvwxyz'
String.LOWER_ARGS    = 'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'

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
-- Creates a pretty string representation of an object. Differs from native
-- @{tostring} in that it knows about factorio userdata and can show
-- the content of tables.
--
-- __Note:__ For pretty printing only. Result is not guaranteed to be loadable.
--
-- @tparam AnyValue object
-- @treturn string
-- @usage
--   for _,v in pairs{nil,true,42,'test',LuaPlayer,LuaPosition,function()end} do
--     print(String.tostring(v))
--     end
--
--   > nil
--   > true
--   > 42
--   > test
--   > {<userdata>}
--   > {x = -17.2109375, y = 14.265625}
--   > <function>
--
-- @function String.tostring

String.tostring = Meta.SwitchCase(type,{
  ['default' ] = function( ) return '<unknown>'                 end,
  ['nil'     ] = function( ) return 'nil'                       end,
  ['boolean' ] = real_tostring                                     ,
  ['number'  ] = real_tostring                                     ,
  ['string'  ] = function(x) return  x                          end,
  ['thread'  ] = function( ) return '<thread>'                  end,
  ['function'] = function( ) return '<function>'                end,
  ['userdata'] = function( ) return '{<userdata>}'              end,
  ['table'   ] = function(x)
    if type(x.__self) == 'userdata' then return '{<userdata>}' -- factorio object
    else return Hydra.line(x,{nocode=true}) end
    end,
  })

  
  
-- -------------------------------------------------------------------------- --
-- Proof of Concepts / Drafts / Other Garbage                                 --
-- -------------------------------------------------------------------------- --

  
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
