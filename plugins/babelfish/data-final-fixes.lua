-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
local Data  = elreq('erlib/factorio/Data/!init')()
local const = require 'plugins/babelfish/const'

local PluginManager = elreq('erlib/factorio/PluginManagerLite-1')()
local asset = PluginManager.make_asset_getter('babelfish')

-- -------------------------------------------------------------------------- --

Data.Inscribe{
  name          = const.sprite.default_icon     ,
  type          = 'sprite'                      ,
  filename      = asset 'babelfish-256-mip4.png',
  size          = 256                           ,
  mipmap_count  = 4                             ,
  flags         = {'gui-icon'}                  ,
  }

  
data.raw['gui-style']['default']
  [const.style.status_indicator_button] = { -- from vanilla "transparent_slot"
    type = "button_style",
    parent = "button",
    size = 32,
    padding = 0,
    default_graphical_set = {},
    clicked_graphical_set = {},
    hovered_graphical_set = {},
    clicked_vertical_offset = 0,
    draw_shadow_under_picture = true,
    pie_progress_color = {0.98, 0.66, 0.22, 0.5},
    left_click_sound = {},
    }
