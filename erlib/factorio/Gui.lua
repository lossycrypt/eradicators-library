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

local Table       = elreq('erlib/lua/Table'        )()
local Array       = elreq('erlib/lua/Array'        )()


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Gui,_Gui,_uLocale = {},{},{}

-- -------
-- Nothing.
-- @within Todo
-- @field todo1

--------------------------------------------------------------------------------
-- Generic.
-- @section
--------------------------------------------------------------------------------

----------
-- Destroys a gui element or does nothing.
-- @tparam[opt] LuaGuiElement elm
function Gui.destroy(elm)
  if elm then elm.destroy() end
  end

----------
-- Recursively find a named element. Depth-first search.
-- @tparam LuaGuiElement parent The element to start searching at.
-- @tparam string name
-- @treturn nil|LuaGuiElement The first element with a matching name, if any.
--
function Gui.find_child (parent, name)
  if parent.name == name then
    return parent
    end
  for _, elm in pairs(parent.children) do
    if elm.name == name then
      return elm
    else
      local r = Gui.find_child(elm, name)
      if r then return r end
      end
    end
  end
  
----------
-- Gets all elements above an element.
-- Most useful to get the anchor element or the name of the root.
-- 
-- @tparam LuaGuiElement elm
-- @treturn DenseArray Starts at the root element (screen, relative, etc.) and
-- ends at the input element.
function Gui.get_ancestors(elm)
  local i, r = 1, {elm}
  repeat; i = i + 1
    r[i] = elm.parent
    elm = r[i]
    until not r[i]
  return Array.reverse(r) end
  
--------------------------------------------------------------------------------
-- Screen.
-- @section
--------------------------------------------------------------------------------

  
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

  
----------
-- Creates a draggable title-bar with close button.
-- Mimics vanilla style in accordance with
-- [Raiguards Style Guide](https://github.com/raiguard/Factorio-SmallMods/wiki/GUI-Style-Guide)
--
function Gui.create_title_bar(opts)
  -- A standardtized frame title bar
  -- [1] https://github.com/raiguard/Factorio-SmallMods/wiki/GUI-Style-Guide

  -- (Originally from skin-swapper)
  
  local anchor = opts.anchor
  
  assert(#anchor.children == 0, 'Anchor already has children.')
  
  --title flow
  local title = anchor.add{
    type      = 'flow',
    direction = 'horizontal',
    }
  title.drag_target = opts.drag_target -- gui.screen only 
  local label = title.add{
    type    = 'label',
    caption = assert(opts.caption),
    style   = 'frame_title',
    }
  label.ignored_by_interaction = true -- required for dragging...wth
  local drag = title.add{
    type  = 'empty-widget',
    style = 'draggable_space_header',
    }
  drag.style.height = 24
  drag.style.horizontally_stretchable = true
  drag.style.right_margin = 4
  drag.ignored_by_interaction = true -- required for dragging...wth
  
  local closebutton = title.add{
    name                = assert(opts.close_button_name),
    type                = 'sprite-button'       ,
    style               = 'frame_action_button' ,
    sprite              = 'utility/close_white' ,
    hovered_sprite      = 'utility/close_black' ,
    clicked_sprite      = 'utility/close_black' ,
    mouse_button_filter = {'left'}              ,
    }
  end
  
--------------------------------------------------------------------------------
-- AutoStyler.
-- @section
-- @usage
--   -- settings.lua
--   erlib_enable_plugin('gui-auto-styler')
--------------------------------------------------------------------------------
do

  local const = require '__eradicators-library__/plugins/gui-auto-styler/const'

  ----------
  -- Automatically updates this sliders tooltip when it's value changes.
  -- 
  -- @tparam LuaGuiElement elm
  -- @tparam LocalisedString|string postfix
  -- @treturn LuaGuiElement The given element.
  function Gui.set_slider_auto_tooltip(elm, postfix)
    local tags = elm.tags
    local data = Table.sget(tags, const.path.style_data, {})
    data[const.index.style_data.slider_value_tooltip_postfix] = postfix or ''
    elm.tags = tags
    -- initialize tooltip. @future: call the real event handler
    elm.tooltip = {'', elm.slider_value, postfix} -- Not working for unknown reason.
    return elm end

  end
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Gui') end
return function() return Gui,_Gui,_uLocale end
