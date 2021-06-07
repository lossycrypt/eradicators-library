-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module LocalisedString
-- @usage
--  local LocalisedString = require('__eradicators-library__/erlib/factorio/LocalisedString')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local LocalisedString,_LocalisedString,_uLocale = {},{},{}


--------------------------------------------------------------------------------
-- Section.
-- @section
--------------------------------------------------------------------------------

----------
-- Nothing.
-- @within Todo
-- @field todo1


-- -------------------------------------------------------------------------- --
-- Legacy Draft (Power String)                                                --
-- -------------------------------------------------------------------------- --

-- convert between actual numbers and "10GW" "200kW" style strings.
-- see also https://forums.factorio.com/viewtopic.php?p=446016#p446016
--@number: the input number (or number string) to be formatted
--@unit: "W" Watt, or whatever"
--@precision: the number of decimal points to keep
local prefixes = {
  [3 ] = "kilo" , [6 ] = "mega" , [9 ] = "giga" ,
  [12] = "tera" , [15] = "peta" , [18] = "exa"  ,
  [21] = "zetta", [24] = "yotta",  
  }
function misc .power_string_from_number(number,unit,precision)
  precision = math.max(0,math.floor(tonumber(precision) or 0))
  number    = tonumber(number) or 0
  local l = (number == 0) and 1 or math.floor(math.log(math.abs(number),10))
  local n = math.min(24,l - (l % 3))
  print('num',number,l,n)
  return {
    "",
    string.format("%."..precision.."f",number/10^n),
    prefixes[n] and {"si-prefix-symbol-"..prefixes[n]} or unit,
    prefixes[n] and unit or nil
  }
end

-- local function test(x) print(x[2],x[3][1],(x[4] or {})[1]) end --[[out-of-game testing]]
-- test(misc .power_string_from_number(1234.567890,{"si-unit-symbol-watt"}))
-- test(misc .power_string_from_number(12345670,{"si-unit-symbol-watt"},2))
-- test(misc .power_string_from_number(1234567890,{"si-unit-symbol-watt"},2))
-- test(misc .power_string_from_number(12345600000000000000000000000007890,{"si-unit-symbol-watt"},2))
-- test(misc .power_string_from_number(-12.6667,{"si-unit-symbol-watt"},2))
-- test(misc .power_string_from_number("a",{"si-unit-symbol-watt"},-2))
-- testing

function misc .power_string_to_number()
  end
  
function misc .power_string_multiply(power_string,factor)
  end



-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.LocalisedString') end
return function() return LocalisedString,_LocalisedString,_uLocale end
