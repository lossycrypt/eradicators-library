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
-- colored info icons

for _, color in pairs{'default', 'red', 'green'} do
  Data.Inscribe{
    name          = const.sprite['icon_'..color]              ,
    type          = 'sprite'                                  ,
    filename      = asset 'babelfish-'..color..'-256-mip4.png',
    size          = 256                                       ,
    mipmap_count  = 4                                         ,
    flags         = {'gui-icon'}                              ,
    }
  end

-- -------------------------------------------------------------------------- --
-- status indicator
  
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

-- -------------------------------------------------------------------------- --
-- tips

data:extend{{
  type = 'tips-and-tricks-item',
  name = const.name.tip_1,
  localised_name = {'babelfish.babelfish'},
  category = require ('__eradicators-library__/plugins/tips-group/const')
             .tips.category_name,
  starting_status = "not-to-be-suggested",
  indent = 1,
  tag = ('[img=%s] '):format(const.sprite.icon_default),
  order = 'babelfish',
  -- trigger = {
  --   There is no lua-script based trigger. (base 1.1.34)
  --   type = "time-elapsed",
  --   ticks = 60 * 60 * 5, -- 5 minutes
  --   ticks = 1,
  --   },
  }}