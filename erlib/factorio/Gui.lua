-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Gui
-- @usage
--  local Gui = require('__eradicators-library__/erlib/factorio/Gui')()
  
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

local Gui,_Gui,_uLocale = {},{},{}

-- -------
-- Nothing.
-- @within Todo
-- @field todo1

--------------------------------------------------------------------------------
-- Section.
-- @section
--------------------------------------------------------------------------------

----------
-- Destroys a gui element or does nothing.
-- @tparam[opt] LuaGuiElement elm
function Gui.destroy(elm)
  if elm then elm.destroy() end
  end

----------
-- Moves a @{FOBJ LuaGuiElement} inside @{FOBJ LuaGui.screen}.
--
-- @tparam LuaGuiElement elm
-- @tparam NaturalNumber w Width
-- @tparam NaturalNumber h Height
-- @tparam[opt=0.5] UnitInterval x Relative center position on the x axis.
-- @tparam[opt=0.5] UnitInterval y
--
-- @treturn LuaGuiElement The given element.
function Gui.move(elm, w, h, x, y)
  x,y = x or 0.5, y or 0.5 --range 0~1, how far on each axis the elm center is displaced from center
  local p     = game.players[elm.player_index]
  local res   = p.display_resolution
  local scale = p.display_scale
  local loc   = {(res.width - (w*scale)) * x, (res.height - (h*scale)) * y}
  elm.location = loc
  elm.style.width,elm.style.height = w, h
  return elm end

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Gui') end
return function() return Gui,_Gui,_uLocale end
