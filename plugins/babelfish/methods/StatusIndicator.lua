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

-- local Stacktrace  = elreq('erlib/factorio/Stacktrace')()

local Table       = elreq('erlib/lua/Table'     )()
-- local Setting       = elreq('erlib/factorio/Setting'     )()
-- local Cache       = elreq('erlib/factorio/Cache'     )()
-- local Set         = elreq('erlib/lua/Set'       )()

-- local Verificate  = elreq('erlib/lua/Verificate')()
-- local verify      = Verificate.verify

-- local join_path   = elreq('erlib/factorio/Data/!init')().Path.join

-- local require     = _ENV. require -- keep a proper reference

-- local Setting = elreq('erlib/factorio/Setting')()

-- local Hydra = elreq('erlib/lua/Coding/Hydra')()

-- local ntuples = elreq('erlib/lua/Iter/ntuples')()

local Gui = elreq('erlib/factorio/Gui')()

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
-- local script = EventManager .get_managed_script   'babelfish'
local import = PluginManager.make_relative_require'babelfish'
local const  = import '/const'
-- local ident  = serpent.line

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --


local StatusIndicator = {}

local button_name = const.sprite.default_icon -- temporary

local minimap_width = 254
local ups_counter_width = 196
local function get_loc(p)
  local res = p.display_resolution
  local scale = p.display_scale
  local x_offset = minimap_width + ups_counter_width + 32 + 4
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
  button.style.width  = 32
  button.style.height = 32
  button.show_percent_for_small_numbers = true
  return button end

  
function StatusIndicator.update(p, percent, tooltip)
  local button = sget_indicator(p)
  button.tooltip = tooltip
  button.number = percent / 100
  button.location = get_loc(p)
  end
  
-- function StatusIndicator.update_all()
  -- for _, p in pairs(game.connected_players) do
    -- local button = sget_indicator(p)
    -- button.tooltip = 'eh?'
    -- button.number = 0.34
    -- end
  -- end
  
  
function StatusIndicator.destroy_all()
  for _, p in pairs(game.players) do
    Gui.destroy(p.gui.screen[button_name])
    end
  end
  
  
return StatusIndicator  