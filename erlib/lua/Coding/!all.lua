-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- En-/Decodes to/from various formats.
-- You can require all sub-modules at once by requiring "!all".
--
-- @module Coding
-- @usage
--  local Coding = require('__eradicators-library__/erlib/lua/Coding/!all')()
  
  

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
Coding.Hydra = require 'erlib/lua/Coding/Hydra'

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





  



-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
return function() return Coding,_Coding,_uLocale end
