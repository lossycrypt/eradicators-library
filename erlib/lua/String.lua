-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
--
--
-- @{Introduction.DevelopmentStatus|Module Status}: Experimental 2020-10-31.
--
-- @module String
-- @usage
--  local String = require('__eradicators-library__/erlib/lua/String')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local type,string = type,string

local string_gsub,string_gmatch,string_find,string_format,string_sub,
      table_concat,math_floor,math_ceil,string_lower
    = string.gsub,string.gmatch,string.find,string.format,string.sub,
      table.concat,math.floor,math.ceil,string.lower

local Hydra    = elreq ('erlib/lua/Coding/Hydra')()
local Meta     = elreq ('erlib/lua/Meta/!init')()

local stop = elreq('erlib/lua/Error')().Stopper('String')

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local String,_String,_uLocale = {},{},{}


--------------------------------------------------------------------------------
-- Constants.
-- @section
--------------------------------------------------------------------------------

--- 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
String.UPPER_LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
--- 'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z'
String.UPPER_ARGS    = 'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z'
--- 'abcdefghijklmnopqrstuvwxyz'
String.LOWER_LETTERS = 'abcdefghijklmnopqrstuvwxyz'
--- 'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
String.LOWER_ARGS    = 'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
--- A dense array of different unicode spaces. (From [here](https://emptycharacter.com))
-- @table String.UNICODE_SPACE
do end
String.UNICODE_SPACE = {'%s',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','　'}

--------------------------------------------------------------------------------
-- Analyze strings.
-- @section
--------------------------------------------------------------------------------

----------
-- Counts number of occurances of pattern in string.
-- @tparam string str
-- @tparam Pattern pattern
-- @treturn NaturalNumber 
function String.count(str,pattern)
  -- Empty gsub() replace is 7% faster than find() loop.
  -- Local gsub is 2% faster than str:gsub().
  -- All types of "select(2,...)" are slower due to function overhead.
  local _,c = string_gsub(str,pattern,'')
  return c
  end
  
  
--------------------------------------------------------------------------------
-- Create strings.
-- @section
--------------------------------------------------------------------------------

----------
-- Creates a pretty string representation of an object. Differs from native
-- @{tostring} in that it knows about factorio userdata and can show
-- the content of tables.
--
-- See also @{FOBJ Common.object_name}.
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
--   > {<LuaPlayer>}
--   > {x = -17.2109375, y = 14.265625}
--   > <function>
--
-- @function String.to_string
do

  local hydra_options = {
    sortkeys = true , -- line: true
    comment  = false, -- line: false
    sparse   = false, -- line: false?
    nocode   = true , -- line: true?
    indent   = nil  , -- line: nil
    compact  = false, -- line: false
    }

  local Hydra_serialize = Hydra.serialize -- skip Hydra internal option merging.

  -- Copied code: String.to_string, Log._to_table_of_strings, Error.simplify
  local f_tostring = {
    ['nil'     ] = function( ) return '<nil>'      end,
    ['number'  ] = _ENV .tostring                     ,
    ['boolean' ] = _ENV .tostring                     ,
    ['string'  ] = function(x)
      if x ~= '' then return x
      else return '<empty string>' end end,
    ['thread'  ] = function( ) return "<thread>"   end,
    ['function'] = function( ) return "<function>" end,
    ['userdata'] = function( ) return "<userdata>" end,
    ['table'   ] = function(x) return Hydra_serialize(x,hydra_options) end,
    }

  function String.to_string (obj)
    -- Performance:
    -- For strings it would be 20% faster to not call any function
    -- at all, but checking if obj *is* a string makes *all other*
    -- data types 20% slower.
    return f_tostring[type(obj)](obj)
    end
  end
 
--------------------------------------------------------------------------------
-- Create tables.
-- @section
--------------------------------------------------------------------------------


----------
-- Find all occurances of a pattern in a string.
-- @tparam string str
-- @tparam Pattern pattern
-- @tparam[opt=false] boolean multi_capture If the pattern can return more than
-- one capture at a time. If true the result will return a sub-table for every
-- group of captures. If false the result will be a plain array of strings.
--
-- @usage 
--   local test = 'ABCDEFG'
--   print(String.to_string(String.find_all(test,'(..)')))
--   > {"AB", "CD", "EF"}
--
--   print(String.to_string(String.find_all(test,'(.)(.)')))
--   > {"A", "C", "E"}
--
--   print(String.to_string(String.find_all(test,'(.)(.)',true)))
--   > {{"A", "B"}, {"C", "D"}, {"E", "F"}}
--
function String.find_all(str,pattern,multi_capture)
  local matches = {}
  local f = string_gmatch(str,pattern)
  -- local r
  if multi_capture then
    repeat
      local r = {f()}
      matches[#matches+1] = r
      until #r == 0
    matches[#matches] = nil --remove empty capture at the end
  else
    repeat
      local r =  f() 
      matches[#matches+1] = r
      until r == nil
    end
  return matches
  end

----------
-- Factorio style "fuzzy" string search.
-- For true factorio style matching you must
-- @{String.remove_whitespace|remove all whitespace}
-- from your input pattern.
-- 
-- @usage
--   local needle   = 'r p e'
--   local haystack = 'Iron Plate'
--   print(String.find_fuzzy(
--     haystack:lower(), String.to_array(String.remove_whitespace(needle:lower()))
--     ))
--   > true
--
-- @tparam string str
-- @tparam DenseArray pattern An array of strings (see @{String.to_array}).
-- 
-- @treturn boolean Is true when each character in pattern
-- occurs in str in the same order.
-- 
function String.find_fuzzy(str, pattern)
  local _, start = nil, 0
  for i = 1, #pattern do
    _, start = string_find(str, pattern[i], start + 1, true)
    if not start then return false end
    end
  return true end
  
----------
-- Splits a string into an array of sub-strings. The pattern
-- is entirely removed from the result.
--
-- @tparam string str
-- @tparam Pattern pattern
-- @tparam boolean raw If the pattern should be treated as a raw string.
-- See @{string.find} "plain".
--
-- @treturn table 
--
-- @usage
--   local test = 'AB12CD34EF56'
--   print(String.to_string(String.split(test,'%d%d')))
--   > {"AB", "CD", "EF"}
--
--   print(String.to_string(String.split(test,'%a%d')))
--   > {"A", "2C", "4E", "6"}
--
function String.split(str,pattern,raw)
  if pattern == '' then stop('Can not split by empty string.') end
  local r, n = {}, 0
  local s = 1
  while true do
    n = n + 1
    local i,j = string_find(str,pattern,s,not not raw)
    if not i then break end
    r[n] = string_sub(str,s,i-1)
    s = j+1
    end
  if s <= #str then
    r[n] = string_sub(str,s) -- rest after the last find
    end
  return r
  end  

----------
-- Converts a string into an array of characters.
-- Has limited unicode awareness.
--
-- @tparam string ustr
-- @treturn DenseArray
function String.to_array(ustr)
  local r, i = {}, 0
  -- From http://lua-users.org/wiki/LuaUnicode
  -- %z with \0 as it's deprecated according to the official manual.
  for uchar in string.gmatch(ustr, "(['\0\1-\127\194-\244][\128-\191]*)") do
    i = i + 1
    r[i] = uchar
    end
  return r end
  
  
--------------------------------------------------------------------------------
-- Manipulate strings.
-- @section
--------------------------------------------------------------------------------

--- Trims whitespace from both sides of a string.
-- @tparam string str
-- @treturn string
function String. trim(str) return str:match"^%s*(.-)%s*$" end
--- Trims whitespace from left side of a string.
-- @tparam string str
-- @treturn string
function String.ltrim(str) return str:match"^%s*(.-)$"    end
--- Trims whitespace from right side of a string.
-- @tparam string str
-- @treturn string
function String.rtrim(str) return str:match"^(.-)%s*$"    end

----------
-- Removes all whitespace from a string.
-- Does not remove line breaks.
-- Uses @{String.UNICODE_SPACE}.
-- @tparam string ustr
-- @treturn string
function String.remove_whitespace(ustr)
  -- Unicode spaces have to be removed one-by-one to
  -- not produce garbage output.
  for i=1, #String.UNICODE_SPACE do 
    ustr = string_gsub(ustr, String.UNICODE_SPACE[i], '')
    end
  return ustr end
  
----------
-- Replaces a raw substring with another raw substring.
-- Similar to @{string.gsub}, but ignores all Lua @{Patterns}.
--
-- @tparam string str
-- @tparam string pattern
-- @tparam string replacement
-- @tparam[opt=inf] NaturalNumber n How often the pattern should be replaced.
-- Specify @{nil} for infinite.
-- @tparam[opt=true] boolean raw If the pattern and replacement are raw
-- strings. Non-raw calls will be redirected to native @{string.gsub}.
--
-- @treturn string The new replacified string.
-- @treturn NaturalNumber How many replacements happend.
--
-- @usage
--   local test = '%a%d%l%a'
--
--   print(String.replace(test,'%a','%d'))
--   > %d%d%l%d 2
--
--   print(String.replace(test,'%a','%d',1))
--   > %d%d%l%a 1
--
function String.replace(str,pattern,replacement,n,raw)
  -- Non-raw mode is faster with native gsub.
  if raw == false then
    return string_gsub(str,pattern,replacement,n)
    end
  -- Raw mode requested by Reika.
  local s,c = 1,0
  n = n or math.huge
  while n > 0 do
    local i,j = string_find(str,pattern,s,true) -- always raw
    if not i then break end
    str = str:sub(1,i-1)..replacement..str:sub(j+1,-1)
    s = j+1
    n = n-1
    c = c+1
    end
  return str,c
  end
  
----------
-- Puts a seperator between each pattern of the input string.
-- @tparam string str
-- @tparam[opt='.']  Pattern pattern
-- @tparam           string seperator (*default* ',')
-- @tparam[opt=1]    double i Start point in str.
-- @tparam[opt=#str] double j End point in str.
--
-- @usage
--   print(String.splice('ABCDEFG','..',':',3,7))
--   > CD:EF
--
function String.splice(str,pattern,seperator,i,j)
  seperator = seperator or ','
  pattern = pattern or '.'
  -- return str
    -- :sub (i or 1,j or #str)        --partial string
    -- :gsub(pattern,'%1'..seperator) --comma seperate
    -- :sub (1,-2)                    --no comma after last
  local r = {}
  for s in str:sub(i or 1,j or #str):gmatch(pattern) do
    r[#r+1] = s
    end
  return table_concat(r,seperator)
  end

----------
-- Either pads or chops a string to an exact length.
-- Too long strings will be chopped up in the middle, too short strings
-- will be either right- or left-padded.
--
-- @tparam string str
-- @tparam NaturalNumber length
-- @tparam[opt=false] boolean left_pad If the padding of short strings should
-- be applied on the left instead of the right side.
--
-- @treturn string 
--
-- @usage
--   local long_test  = 'The quick brown fox jumps over the lazy dog.'
--   local short_test = 'Nice boat.'
--
--   print(String.enforce_length(long_test,21))
--   > "The quick...lazy dog."
--
--   print(String.enforce_length(short_test,21))
--   > "Nice boat.           "
--
--   print(String.enforce_length(short_test,21,true))
--   > "           Nice boat."
--
function String.enforce_length(str,length,left_pad)
  if (length <  5) and (#str > length) then
    -- Inserting triple-dots into a string below length 5 makes no sense.
    stop('Can not shorten strings below length of 5.')
    end
  if #str == length then
    return str
  elseif #str < length then
    --i.e. string.format('%-20.20s')
    if not left_pad then
      return string_format('%-'..length..'.'..length..'s',str)
    else
      return string_format('%+'..length..'.'..length..'s',str)
      end
  else  
    local n,m = math_ceil(length/2)-2,math_floor(length/2)-1
    return str:sub(1,n)..'...'..str:sub(-m)
    end
  end
  
----------
-- Removes spaces, dashes and underscores then capitalizes words.
-- Preserves leading and trailing underscores.
--
-- @usage
--   print(String.to_camel_case '_private_function_name')
--   > _PrivateFunctionName
--   print(String.to_camel_case 'prototype-name')
--   > PrototypeName
--   print(String.to_camel_case '__mod-root__')
--   > __ModRoot__
--   print(String.to_camel_case 'A random sentence!')
--   > ARandomSentence
--
-- @tparam string str
--
-- @treturn string
--
-- @function String.to_camel_case
--
  do local function _up_last (str) return str:sub(-1):upper() end
function String.to_camel_case(str)
  local prefix  = str:match'^[_]*'
  local postfix = str:match '[_]*$'
  local infix   = str
    :gsub('[^%a]+%a',_up_last) -- capitalize letters after non-letters
    :gsub( '^%a'    ,_up_last) -- capitalize first letter
    :gsub('[^%a]*$' ,''      ) -- remove trailing non-letters
  return prefix .. infix .. postfix
  end
  end
  
----------
-- Converts CamelCase or dash-case to snake_case.
--
-- @tparam string str
-- @treturn string
function String.to_snake_case(str)
  return 
    string_lower( -- outside to not leak gsub second return value.
      string_gsub(
        string_gsub(str, '(%a)(%u)', '%1_%2')
        ,'-','_')
      )
  end
  
  
--------------------------------------------------------------------------------
-- Factorio specific
-- @section
--------------------------------------------------------------------------------

----------
-- Removes the rich text tags from a string. Useful for use with LuaRendering
-- which doesn't support them.
--
-- @tparam string str
-- @treturn string
--
-- @usage
--   local test = '[test][color=red]![/color]1[img=bla]2[item=bla]3'
--   print(String.remove_rich_text_tags(test))
--   > [test]!123
function String.remove_rich_text_tags(str)
  --'[test][color=red]![/color]1[img=bla]2[item=bla]3'
  --
  --one or two groups of not-a-closing-square-bracket
  --with an equal or a slash before the second group
  --between one opening and one closing square bracket
  return (str:gsub('%[[^%]]*[=/][^%]]+%]',''))
  end


--------------------------------------------------------------------------------
-- Proof of Concepts / Drafts / Other Garbage
-- @section
--------------------------------------------------------------------------------

----------
-- Converts multi-line functions to one-line.
--
-- Removes new-lines and simple end-of-line comments.
-- 
-- Intended for including local copies of library functions into very
-- simply stand-alone mods.
-- 
-- Does not have any complex handling whatsoever. You have to manually
-- remove multi-line comments, strings containing newlines, strings
-- containing `--`, or anything complicated like that.
--
-- @tparam string str A string representing a function.
-- @treturn The string without new lines.
function String.to_one_line_function(str)
  -- don't forget: gsub returns two values!
  return (str
    -- end-of-line comments
    :gsub('[^\r\n]+',function(s) return s:gsub('%-%-.*$','') end)
    -- remove multi-new-line
    :gsub('%s*[\r\n]+%s*',';'))
  end

----------
-- __PROOF OF CONCEPT__. __SLOW__. Do not use in production.   
-- Python-esque string formatting from locals and upvalues.
--
-- __Quirk:__ Lua functions only see upvalues that they actually
-- use. If an upvalue is not used inside the format-calling function
-- then a same named global variable will be used if it exists.
--
-- @tparam string str The template to be formatted.
--
-- @treturn string The formatted output.
-- @treturn NaturalNumber The total number of formatted patterns.
--
-- @usage
--   -- A variable name in curly brackets is the basic pattern.
--   local t = '{varname}'
--   -- You can also use string.format() syntax.
--   local t = '{varname:2.2f'}
--
-- @usage
--   local F = String.smart_format
--   function test(name,surname)
--     print(F'Hi. My name is {name} {surname}!')
--     end
--   test('E.R.','Adicator')
--   > Hi. My name is E.R. Adicator!
--
-- @function String.smart_format
--
do 
  local debug_getinfo, debug_getupvalue, debug_getlocal
      = debug.getinfo, debug.getupvalue, debug.getlocal
      
  local string_gsub, string_format, tostring, tonumber, setmetatable
      = string.gsub, string.format, tostring, tonumber, setmetatable 
      
  -- Test commands
  -- load_erlib(); bla = '5'; local bla3 = 5; local bla3 = 3 ; local blax = 'blax'; print( (function() return ( F'{bla}{bla2}{bla3}{blax}' ) end)()  )
      
function String.smart_format(str)
  -- [1] http://lua-users.org/lists/lua-l/2004-01/msg00075.html
  -- Identifiers in Lua can be any string of letters, digits, and
  -- underscores, not beginning with a digit.
  local caller = debug_getinfo(2,'f').func
  local values = {}
  --upvalues
  --(only included if the function references them)
  local i=0; while true do i=i+1
    local k,v = debug_getupvalue(caller,i)
    if k == nil then break end
    values[k] = v
    end
  --locals (overshadow upvalues)
  local i=0; while true do i=i+1
    local k,v = debug_getlocal(2,i)
    if k == nil then break end
    values[k] = v
    end
  --globals
  setmetatable(values,{__index=values._ENV or _ENV});
  --format
  return string_gsub(
    str,
    '({([_%a][_%w]*):?(.-)})', -- "{_varname0:tail}", tail is format spec or nil
    function(_,key,tail)
      local value = values[key]
      -- do not replace if no value was found
      if value == nil then return nil end
      -- full string format, default "%s"
      return string_format('%'..((tail == '') and 's' or tail), value )
      -- naive plain text
      -- return tostring(values[key])
      end
    )
  end
  end

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.String') end
return function() return String,_String,_uLocale end
