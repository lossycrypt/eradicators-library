-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- En-/Decodes to/from various formats.
-- You can require all sub-modules at once by requiring "!all".
--
-- @module Coding
-- @usage
--  local Coding = require('__eradicators-library__/erlib/lua/Coding/!init')()

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))
  
-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --
local import = function(path) return (require(elroot..path))() end --unpacking

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Coding,_Coding,_uLocale = {},{},{}



--------------------------------------------------------------------------------
-- Hydra.
-- See the [official repository](https://github.com/pkulchenko/serpent)
-- for detailed usage instructions.
--
-- This is a customized version of "serpent" - renamed to avoid confusion
-- with Factorios built-in serpent installation.
-- This page only documents __changes__ compared to serpent.
--
--  * Equal to Factorios built-in serpent, Hydra represents redundant sub-tables
-- references by the number 0 zero (instead of @{nil} like normal serpent does).
--
--  * Hydra knows about factorio userdata like LuaEntity, LuaPlayer, etc..
--
-- @section
--
-- @usage
--  local Hydra = require('__eradicators-library__/erlib/lua/Coding/Hydra')()
--------------------------------------------------------------------------------
Coding.Hydra = import 'erlib/lua/Coding/Hydra'

----------  
-- Hydra implements some new options that are not in serpent. These work for
-- all presets but are off by default, except for Hydra.lines, where they are on.
--
-- @field indentlevel @{NaturalNumber}, limits indentation of very deep sub-tables.
-- @field showref @{boolean}, adds a comment to the output of self-referencing sub-tables.
-- @table HydraOptions
  
----------
-- Multi-line serialization preset. A more readable, more informative alternative to
-- Hydra.block(). Defaults to indentlevel = 1, showref = true, nocode = true.
--
-- @function Hydra.lines
--
-- @tparam AnyValue object
-- @tparam HydraOptions options
--
-- @usage
--   local t = {'a','b','c'}; t = {t,{t,t},{t,t,t},[42]={{{{{table.insert}}}}}}
--   local opts={indentlevel=1,showref=true,nocode=true} --"lines" mode default
--   print(Hydra.lines(t,opts))
--
--   > {
--   >   {"a", "b", "c"},
--   >   {0 --[[ self[1] ]], 0 --[[ self[1] ]]},                    --self-ref comment
--   >   {0 --[[ self[1] ]], 0 --[[ self[1] ]], 0 --[[ self[1] ]]}, --one level indented
--   >   [42] = {{{{{function()end}}}}}                            --short code skip
--   > }
--
-- @usage
--  print(Hydra.lines{game, game.player, game.player.force})
--  > {
--  >   {__self = "LuaGameScript"},
--  >   {__self = "LuaPlayer"},
--  >   {__self = "LuaForce"}
--  > }

----------
-- Single-line serialization preset.
-- @function Hydra.line

----------
-- Pretty printable serialization preset.
-- @function Hydra.block

----------
-- Raw serialize with recursive tables preset.
-- @function Hydra.dump

----------
-- Deserialization.
-- @function Hydra.load

----------
-- Raw serpent.
-- @function Hydra.serialize

----------
-- Alias of Hydra.dump
-- @function Hydra.encode

----------
-- Similar to Hydra.load, but only has one return value.
-- @tparam string data a serialized table
-- @treturn AnyValue|nil the value that was encoded or nil if decode failed.
-- If @{nil} is a valid return value for your data then this is ambiguous and
-- you should consider handling Hydra.load directly.
-- @function Hydra.decode



--------------------------------------------------------------------------------
-- Bluestring.
--
-- En-/Decodes to/from factorio blueprint exchange string format.
-- Warning: No verification of in or output is done. This is simply a shortcut
-- for the required Json+Zip+Base64+VersionByte'0' function chain.
--
-- See [blueprint string format](https://wiki.factorio.com/Blueprint_string_format)
-- on the wiki for further information.
--
-- __Note:__ serpent serialization is only for json-incompatible
-- mod data. The resulting string will not be blueprint comatible.
--
-- __Note:__ uses
--   @{FOBJ LuaGameScript.encode_string} and
--   @{FOBJ LuaGameScript.decode_string} and
--   @{FOBJ LuaGameScript.table_to_json} and 
--   @{FOBJ LuaGameScript.json_to_table} when available and native lua otherwise.
--
-- @section
--
-- @usage
--  local Bluestring = require('__eradicators-library__/erlib/lua/Coding/Bluestring')()
--------------------------------------------------------------------------------
Coding.Bluestring = import 'erlib/lua/Coding/Bluestring'

----------
-- @tparam table|string data Tables will be serialized to strings before compression.
-- @tparam[opt='json'] string|nil serializer, 'json' or 'serpent'.
-- @tparam[opt='0'] string prefix, the version marker byte
-- @treturn string|nil the encoded string, or nothing if encoding failed.
-- @function Bluestring.encode
-- @usage LuaItemStack.import_stack(Bluestring.encode(my_bp_table))

----------
-- @tparam string data an encoded string
-- @tparam[opt='json'] string|nil|false deserializer, 'json' or 'serpent'.
-- If set to false the data is decompressed but not deserialized.
-- @tparam[opt='0'] string prefix, the version marker byte
-- @treturn table|nil a fresh lua table, or nothing if decoding failed.
-- @function Bluestring.decode
-- @usage local my_bp_table = Bluestring.decode(LuaItemStack.export_stack())



--------------------------------------------------------------------------------
-- Base64.
--
-- En-/Decodes to/from base64 encoding.
-- ([Source](http://lua-users.org/wiki/BaseSixtyFour))
--
-- @section
--
-- @usage
--  local Base64 = require('__eradicators-library__/erlib/lua/Coding/Base64')()
--------------------------------------------------------------------------------
Coding.Base64 = import 'erlib/lua/Coding/Base64'

----------
-- @tparam string data the original string
-- @treturn string the encoded string
-- @function Base64.encode

----------
-- @tparam string data encoded string
-- @treturn string the original string
-- @function Base64.decode
  

  
--------------------------------------------------------------------------------
-- Json.
--
-- En-/Decodes to/from json.
-- ([Source](https://github.com/rxi/json.lua))
--
-- @section
--
-- @usage
--  local Json = require('__eradicators-library__/erlib/lua/Coding/Json')()
--------------------------------------------------------------------------------
Coding.Json = import 'erlib/lua/Coding/Json'

----------
-- @tparam string data the original string
-- @treturn string the encoded string
-- @function Json.encode

----------
-- @tparam string data the encoded string
-- @treturn string the original string
-- @function Json.decode

  
  
--------------------------------------------------------------------------------
-- Zip.
--
-- En-/Decompresses to/from zip deflate.
-- ([Source](https://github.com/SafeteeWoW/LibDeflate))
--
-- @section
--
-- @usage
--  local Zip = require('__eradicators-library__/erlib/lua/Coding/Zip')()
--------------------------------------------------------------------------------
Coding.Zip = import 'erlib/lua/Coding/Zip'

----------
-- @tparam string data the original string
-- @treturn string the compressed string
-- @function Zip.encode

----------
-- @tparam string data the compressed string
-- @treturn string the original string
-- @function Zip.decode

  
--------------------------------------------------------------------------------
-- Crc32.
--
-- Calculates the crc32 hash of the input string.
-- ([Source](https://gist.github.com/SafeteeWoW/080e784e5ebfda42cad486c58e6d26e4))
--
-- @section
--
-- @usage
--  local Crc32 = require('__eradicators-library__/erlib/lua/Coding/Crc32')()
--------------------------------------------------------------------------------
Coding.Crc32 = import 'erlib/lua/Coding/Crc32'


----------
-- @tparam string data the original string
-- @treturn uint|nil 0 < n < 2^32 (4294967296), or nil if it failed.
-- @function Crc32.encode



--------------------------------------------------------------------------------
-- Sha256.
--
-- Calculates the sha256 hash of the input string.
-- ([Source](https://github.com/Egor-Skriptunoff/pure_lua_SHA))
--
-- @section
--
-- @usage
--  local Sha256 = require('__eradicators-library__/erlib/lua/Coding/Sha256')()
--------------------------------------------------------------------------------
-- Coding.Sha256 = (_ENV.bit32) and import 'erlib/lua/Coding/Sha256' or nil
Coding.Sha256 = import 'erlib/lua/Coding/Sha2'

----------
-- @tparam string data the original string
-- @treturn string|nil the hash, or nothing if it failed
-- @function Sha256.encode

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Coding.!init') end
return function() return Coding,_Coding,_uLocale end
