-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
-- -------------------------------------------------------------------------- --

--[[ Notes:
  ]]

--[[ Annecdotes:
  ]]

--[[ Future:
  ]]
  
--[[ Todo:
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
local Data        = elreq('erlib/factorio/Data/!init')()

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local asset  = PluginManager.make_asset_getter('dummy-items', 'eradicators-library')
local import = PluginManager.make_relative_require 'dummy-items'
local const  = import '/const'

-- -------------------------------------------------------------------------- --
-- Unobtanium                                                                 --
-- -------------------------------------------------------------------------- --

Data.Inscribe {
  name  = const.name.item.unobtanium,
  type  = 'item',
  icons = { Data.Sprite.format_icon(asset 'unobtanium-item-64-mip4') },
  flags = { 'hidden', 'only-in-cursor' },
  stack_size = 999,
  }

-- -------------------------------------------------------------------------- --
-- Obtanium                                                                   --
-- -------------------------------------------------------------------------- --

  
Data.Inscribe {
  name  = const.name.item.obtanium,
  type  = 'item',
  icons = { Data.Sprite.format_icon(asset 'obtanium-item-64-mip4') },
  flags = { 'hidden' },
  stack_size = 999,
  }

Data.Inscribe {
  name = const.name.item.obtanium,
  type = 'recipe',
  ingredients = {},
  results = {{const.name.item.obtanium, 1}},
  hidden = not flag.IS_DEV_MODE,
  enabled = false,
  }
  
-- -------------------------------------------------------------------------- --
-- Blueprint Glue                                                             --
-- -------------------------------------------------------------------------- --
  
Data.Inscribe {
  name  = const.name.item.bpglue,
  type  = 'item',
  -- type  = 'item-with-tags',
  icons = { Data.Sprite.format_icon(asset 'blueprint-glue-64-mip4') },
  flags = { 'hidden', 'only-in-cursor' ,
    'primary-place-result', -- prevents conbots from using alternative items.
    },
  stack_size = 999,
  
  -- If place_result is set the engine will
  -- use it's name instead of the item name.
  place_result = nil,
  
  -- No effect?
  order = ('zzzzzzzzzz'),
  }

-- -------------------------------------------------------------------------- --
-- Examples                                                                   --
-- -------------------------------------------------------------------------- --

-- Hidden entities are defined like this:

-- data:extend{{
--   name = 'hidden-entity!',
--   type = 'simple-entity',
--   placeable_by = {item = 'er:blueprint-glue', count = 1}
--   }}
  