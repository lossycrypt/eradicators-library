-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Locale
-- @usage
--  local Locale = require('__eradicators-library__/erlib/factorio/Locale')()
  
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

local Locale,_Locale,_uLocale = {},{},{}

-- -------
-- Nothing.
-- @within Todo
-- @field todo1

-- -----------------------------------------------------------------------------
-- Section.
-- @section
-- -----------------------------------------------------------------------------

----------
-- Merges n localised strings into one.
--
-- Circumvents factorios hard limitation of allowing only
-- up to 20 subtables per localised string by creating 
-- a deeply nested table with < 20 elemenst per level.
--
-- @usage
--   local x = {}
--   for i=65, 65*2 do x[i-64] = string.char(i) end
--   
--   game.print(x)
--   > Error: Too many parameters for localised string: 65 > 20 (limit).
--   
--   game.print(Locale.merge(table.unpack(x)))
--   > ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
--
-- @tparam LocalisedString ...
--
-- @treturn LocalisedString
--
function Locale.merge(...)

  local function pack20(tbl)
    local r = {''} -- empty key joins all following elements.
    for i = 0, #tbl, 20 do
      local segment = {''}
      for j = 1, 20 do
        -- Wrap LuaObjects into brackets.
        -- Factorio automatically extracts the object_name.
        local elm = tbl[i+j]
        segment[#segment+1] = 
          (type(elm) == 'table' and elm.valid) 
          and {'','{',elm,'}'} or elm
        end
      r[#r+1] = segment
      end
    return r
    end

  --[[each level can contain the { _KEY_ ,plus,twenty,strings,or,tables} (engine limitation)]]
  local args = {...}
  repeat args = pack20(args) until #args < 22
  return args
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

I once wrote a function to extract the current localized name of an item in data stage. (original post):

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
(i.e. an official utility function get_localized_name(prototype) -> LocalisedString).
Also looking at this and at the fluid-barrel naming function i'd suspect that the fluid 
barrel recipe doesn't get a correct name if a fluid happens to have a localized_name 
instead of using fluid-name.fluid-name. I.e. because the fluid itself is procedurally 
derived from another prototype.

And even this is incorrect if the entity or equipment declares its own localised_name.
This stuff is tricky. :D


]]
   