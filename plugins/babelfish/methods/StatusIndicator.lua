-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
-- -------------------------------------------------------------------------- --

--[[ Notes

  + The Indicator is just a small temporary gui element.
    To stay simple it doesn't store any Savedata and
    doesn't care about events.

  ]]

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local log         = elreq('erlib/lua/Log'       )().Logger  'BabelfishStatusIndicator'
local stop        = elreq('erlib/lua/Error'     )().Stopper 'BabelfishStatusIndicator'

local Table       = elreq('erlib/lua/Table'     )()
local Gui         = elreq('erlib/factorio/Gui'  )()

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local import = PluginManager.make_relative_require'babelfish'
local const  = import '/const'

local button_name   = const.gui_name.status_indicator_button
local button_width  = 32
local button_height = 32
local minimap_width     = 254
local ups_counter_width = 196

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local StatusIndicator = {}

-- -------------------------------------------------------------------------- --
-- Status Indicator                                                           --
-- -------------------------------------------------------------------------- --

local function get_loc(p)
  local res      = p.display_resolution
  local scale    = p.display_scale
  local x_offset = minimap_width + ups_counter_width + button_width + 4
  local y_offset = 8
  return {
    res.width  - (x_offset * scale),
     (y_offset * scale)
    }
  end

local function sget_indicator(p)
  local button = p.gui.screen[button_name] 
  if button then return button end
  button = p.gui.screen.add {
      name = button_name,
      style = const.style.status_indicator_button,
      type = 'sprite-button',
      sprite = const.sprite.default_icon,
      }
  button.style.width  = button_width
  button.style.height = button_height
  button.show_percent_for_small_numbers = true
  return button end
  
function StatusIndicator.update(p, percent, tooltip)
  local button    = sget_indicator(p)
  button.tooltip  = tooltip
  button.number   = percent / 100
  button.location = get_loc(p)
  end
  
function StatusIndicator.destroy_all()
  for _, p in pairs(game.players) do
    Gui.destroy(p.gui.screen[button_name])
    end
  end
  
-- -------------------------------------------------------------------------- --
return StatusIndicator  