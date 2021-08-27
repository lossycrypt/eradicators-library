-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Locale
-- @usage
--  local Locale = require('__eradicators-library__/erlib/factorio/Locale')()
  
--[[ Related Forum Theads:

  + Bug Report ("Won't Fix")
    https://forums.factorio.com/98676
    Localised string literal {""} without parameters is converted to
    "" the empty string in on_string_translated.
    => Fixed by Lstring.normalize
  
  ]]
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
-- local log         = elreq('erlib/lua/Log'       )().Logger  'Locale'
local stop        = elreq('erlib/lua/Error'     )().Stopper 'Locale'

-- local Verificate  = elreq('erlib/lua/Verificate')()
-- local verify      = Verificate.verify
local assertify   = elreq('erlib/lua/Error'     )().Asserter(stop)

local Array       = elreq('erlib/lua/Array'     )()
-- local String      = elreq('erlib/lua/String'    )()

local type, tostring
    = type, tostring
    
local table_concat, string_gsub
    = table.concat, string.gsub

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Locale,_Locale,_uLocale = {},{},{}
  
--------------------------------------------------------------------------------
-- Misc.
-- @section
--------------------------------------------------------------------------------
  
----------
-- Applies rich text tags to mimic vanilla hotkey tooltips.
-- Intended to format tooltips for custom guis that can't 
-- use `"__CONTROL-foobar__`" localisation because
-- LuaGuiElement buttons are hardcoded.
--
-- @usage
--   game.print{'', Locale.format_hotkey_tooltip('Left mouse button', 'to do something awesome!')}
--
-- @tparam[opt] string key The hotkey
-- @tparam[opt] string description The description
-- @treturn string A richt-text-tag decorated plain string.
function Locale.format_hotkey_tooltip(key, description)
  -- V1
  -- return table.concat {
  --   '[font=default-semibold]',
  --   '[color=#7dcff3]', key        , '[/color] ',
  --   '[color=#ffe5bd]', description, '[/color]',
  --   '[/font]'
  --   }
  
  -- V2
  assert(key or description, 'Must give either key or description.')
  local r = Array {'[font=default-semibold]'}
  if key then
    r:extend{'[color=#7dcff3]', key        , '[/color] '}
    end
  if description then
    r:extend{'[color=#ffe5bd]', description, '[/color]' }
    end
  r:extend{'[/font]'}
  return table.concat(r) end

--------------------------------------------------------------------------------
-- LocalisedString.
-- @section
--------------------------------------------------------------------------------


----------
-- __In-place.__ Fixes very long localised strings.
--
-- Circumvents factorios hard limitation of allowing only
-- up to 20 parameters per key by creating 
-- a deeply nested table with <= 20 parameters per level.
--
-- Intended to create gui elements or tooltips with
-- procedurally generated content.
--
-- @usage
--   local test = {'', 'This', ' ', 'is', ' ', 'a', ' ', 'very', ' ', 'long'
--                 , ' ', 'string', ' ', 'that', ' ', 'the', ' ', 'engine'
--                 , ' ', 'would', ' ', 'not', ' ', 'normally', ' ', 'allow.'}
--   
--   game.print(test)
--   > Error: Too many parameters for localised string: 25 > 20 (limit).
--   
--   Locale.compress(test)
--   game.print(test)
--   > This is a very long string that the engine would not normally allow.
--
-- @tparam LocalisedString lstring A generically 
-- joined localised string `{"", string_1, lstring_2, ...}`. The
-- key _must_ be `""` the empty string.
-- 
-- @treturn LocalisedString A reference to the now compressed input table.
function Locale.compress(lstring)
  -- Example of workflow:
  -- 5 == #{'',1,2,3,4} 
  -- 3 == #{'',{'',1,2},{'',3,4}}
  -- 2 == #{'',{'',{'',1,2},{'',3,4}}}
  --
  assertify(lstring[1] == '', 'Uncompressible lstring: ', lstring)
  local function pack21()
    local k = 1
    for i = 2, #lstring, 20 do
      k = k + 1
      local t = {''}
      for j = 0, 19 do
        t[j+2] = lstring[i+j]
        lstring[i+j] = nil
        end
      lstring[k] = t
      end
    end
  while #lstring > 21 do pack21() end
  return lstring end
  
-- -------------------------------------------------------------------------- --

  
----------
-- Normalises a localised string.
--
-- Result is __identical__ to a factorio engine
-- `LuaPlayer.request_translation` → `on_string_translated` cycle.
--
-- @tparam LocalisedString lstring
-- 
-- @treturn NormalisedLocalisedString
-- 
-- @function Locale.normalise
do
  --
  local function f(lstring)
    local t = type(lstring)
    if t == 'table' then
      if lstring[1] == '' and #lstring == 1 then
        -- Engine "WontFix" bugfix. Replace `{""}` with "".
        return ''
      else
        local arr = {}
        for i=1, #lstring do arr[i] = f(lstring[i]) end
        return arr end
    elseif t == 'nil' then
      return ''
    else -- (t == 'number') or (t == 'string')
      return tostring(lstring)
      end
    end
  --
  Locale.normalise = f
  Locale.normalize = f
  end
  

--------------------------------------------------------------------------------
-- NormalisedLocalisedString.
-- @section
--------------------------------------------------------------------------------

----------
-- A strict subset of @{FAPI Concepts LocalisedString}.
-- 
-- Contrary to normal LocalisedString a NormalisedLocalisedString
-- __does not contain__ @{number} or @{nil} values. Each number value
-- is cast to `string`. Each `nil` value and each `{""}` (_key-free
-- localised string without paramters_) is replaced by an @{EmptyString}.
-- 
-- Localised strings read from Lua*Prototypes 
-- (i.e. `localised_name` or `localised_description`) are 
-- pre-normalized by the factorio engine.
-- 
-- Processing NormalisedLocalisedString requires fewer type checks,
-- making it significantly faster.
-- 
-- @table Locale.NormalisedLocalisedString


----------
-- Measures the size of a NormalisedLocalisedString.  
-- Result is __almost identical__ to `#serpent.line(nlstring, {compact = true})`
-- but 50 times faster.
-- 
-- The only known differences to serpent is that `\n` (_  escaped newline_)
-- is counted as one byte, but it's string representation has two bytes.
-- 
-- @tparam NormalisedLocalisedString nlstring
-- 
-- @treturn NaturalNumber The approximate size in bytes.
--     
-- @function Locale.nlstring_size
do
  local function f(nlstring)
    if type(nlstring) == 'table' then
      local n = f(nlstring[1])
      for i=2, #nlstring do n = n + f(nlstring[i]) + 1 end -- one , comma
      return n + 2 -- two {} brackets
    else
      -- V1
      return #nlstring + 2 -- two "" quotes
      -- V2
      -- Escaped newlines costs one extra byte each,
      -- but counting them costs twice as much as the
      -- rest of the function (40 microseconds without, 120 with counting).
      -- Even #nlstring_to_string() would be faster! (~80 microseconds).
      -- So it's not worth it for such a tiny edge-case.
      --
      -- return String.count(nlstring, '\010') + #nlstring + 2
      end
    end
  Locale.nlstring_size = f
  end
  

----------
-- Serializes a NormalisedLocalisedString.  
-- Result is __identical__ to `serpent.line(lstring, {compact = true})`
-- but 14 times faster.
-- 
-- @tparam NormalisedLocalisedString nlstring
-- 
-- @treturn string
-- 
-- @function Locale.nlstring_to_string
do
  local function f(nlstring, arr)
    if type(nlstring) == 'string' then
      arr[#arr+1] = '\"'
      arr[#arr+1] = nlstring
      arr[#arr+1] = '\"'
    else -- type(nlstring) == 'table'
      arr[#arr+1] = '{'
      for i=1, #nlstring-1 do 
        f(nlstring[i], arr)
        arr[#arr+1] = ','
        end
      f(nlstring[#nlstring], arr)
      arr[#arr+1] = '}'
      end
    return arr end
  --
  Locale.nlstring_to_string = function(nlstring)
    -- V1
    -- return table_concat(f(nlstring, {}))
    -- V2
    -- escape NEWLINE/010 to be identical to serpent (roughly 20% slower).
    return string_gsub(table_concat(f(nlstring, {})), "\010", "\\n")
    end
  end


----------
-- Test if two NormalisedLocalisedStrings are equal.  
-- Result is __identical__ to `Table.is_equal(A, B)` but 3 times faster.
--
-- @tparam NormalisedLocalisedString A
-- @tparam NormalisedLocalisedString B
--
-- @treturn boolean
--
-- @function Locale.nlstring_is_equal
do
  local is_str = {string = true, table = false}
  local function f(A, B)
    if A == B then return true end
    if is_str[type(A)] or is_str[type(B)] then return false end
    local n = #A; if n ~= #B then return false end
    for i=1, n do if not f(A[i], B[i]) then return false end end
    return true end
  --
  Locale.nlstring_is_equal = f
  end
  
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Locale') end
return function() return Locale,_Locale,_uLocale end


-- -------------------------------------------------------------------------- --
-- Draft                                                                      --
-- -------------------------------------------------------------------------- --


--[[ https://forums.factorio.com/viewtopic.php?f=28&t=62107&p=425905#p425905

I once wrote a function to extract the current localised name of an item in data stage. (original post):

  eradicator wrote:
  Here's the hopefully 100% correct version: (protip: is wrong :/ @2019-05-04)

  local derived --courtesy of eradicator
    if item.localised_name then
        derived = item.localised_name
    elseif item.place_result then
        derived = 'entity-name.'..item.place_result -- prototype could have localised_name override
    elseif item.placed_as_equipment_result then
        derived = 'equipment-name.'..item.placed_as_equipment_result
    else
        derived = 'item-name.'..item.name
    end

So i can wholeheartedly agree that it would be awesome to not have to guess this myself. 
(i.e. an official utility function get_localised_name(prototype) -> LocalisedString).
Also looking at this and at the fluid-barrel naming function i'd suspect that the fluid 
barrel recipe doesn't get a correct name if a fluid happens to have a localised_name 
instead of using fluid-name.fluid-name. I.e. because the fluid itself is procedurally 
derived from another prototype.

And even this is incorrect if the entity or equipment declares its own localised_name.
This stuff is tricky. :D


]]
   