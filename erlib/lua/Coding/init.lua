-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- En-/Decodes to/from various formats.
-- You can require all sub-modules at once by requiring "!all".
--
-- @module Coding
-- @usage
--  local Coding = require('__eradicators-library__/erlib/lua/Coding/!all')()
  
-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- -------------------------------------------------------------------------- --
-- local elroot = (function(_) return (pcall(require,_..'erlib/empty')) and _ or '' end)('__eradicators-library__/')  
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'

local import = function(path) return (require(elroot..path))() end

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
-- This page only documents changes compared to serpent.
-- Equal to factorios built-in serpent Hydra represents self-referenced sub-tables
-- by the number 0 zero (instead of @{nil} like normal serpent does).
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
-- Multi-line serialization. A more readable, more informative alternative to
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

----------
-- Single-line serialization
-- @function Hydra.line

----------
-- Pretty printable serialization.
-- @function Hydra.block

----------
-- Raw serialize with recursive tables.
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
-- Alias of Hydra.load
-- @function Hydra.decode



--------------------------------------------------------------------------------
-- Base64.
--
-- En-/Decodes to/from base64 encoding.
-- From this [repository](https://github.com/DaveMcW/blueprint-string/blob/master/blueprintstring/base64.lua).
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
-- From this [repository](https://github.com/rxi/json.lua/blob/master/json.lua).
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
-- From this [repository](https://github.com/DaveMcW/blueprint-string/tree/master/blueprintstring).
--
-- @section
--
-- @usage
--  local Zip = require('__eradicators-library__/erlib/lua/Coding/Zip')()
--------------------------------------------------------------------------------
Coding.Zip = (_ENV.bit32) and import 'erlib/lua/Coding/Zip' or nil


-- Coding.LibDeflate = require (elroot.. 'erlib/lua/Coding/LibDeflate')

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
-- From this [repository](https://github.com/openresty/lua-nginx-module/blob/master/t/lib/CRC32.lua).
--
-- @section
--
-- @usage
--  local Crc32 = require('__eradicators-library__/erlib/lua/Coding/Crc32')()
--------------------------------------------------------------------------------
Coding.Crc32 = import 'erlib/lua/Coding/Crc32'

----------
-- @tparam string data the original string
-- @treturn NaturalNumber the hash
-- @function Crc32.encode



--------------------------------------------------------------------------------
-- Sha256.
--
-- Calculates the sha256 hash of the input string.
-- From this [page](http://lua-users.org/wiki/SecureHashAlgorithm).
--
-- @section
--
-- @usage
--  local Sha256 = require('__eradicators-library__/erlib/lua/Coding/Sha256')()
--------------------------------------------------------------------------------
Coding.Sha256 = (_ENV.bit32) and import 'erlib/lua/Coding/Sha256' or nil

----------
-- @tparam string data the original string
-- @treturn string the base64 encoded hash
-- @function Sha256.encode

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
(STDOUT or log or print)('Loaded → erlib.Coding')
return function() return Coding,_Coding,_uLocale end
