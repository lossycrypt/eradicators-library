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
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local log         = elreq('erlib/lua/Log'          )().Logger  'TipsGroup'
local stop        = elreq('erlib/lua/Error'        )().Stopper 'TipsGroup'

-- local Table       = elreq('erlib/lua/Table'        )()
-- local Setting     = elreq('erlib/factorio/Setting' )()

-- local Verificate  = elreq('erlib/lua/Verificate'   )()
-- local verify      = Verificate.verify

-- local Setting     = elreq('erlib/factorio/Setting' )()
-- local ntuples     = elreq('erlib/lua/Iter/ntuples' )()

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
-- local script = EventManager .get_managed_script    'tips-group'
local PluginManager = elreq('erlib/factorio/PluginManagerLite-1')()
local import = PluginManager.make_relative_require 'tips-group'
local const  = import '/const'

  
-- -------------------------------------------------------------------------- --
-- Draft                                                                      --
-- -------------------------------------------------------------------------- --

data:extend{{
  type  = 'tips-and-tricks-item-category',
  name  = const.tips.category_name,
  order = 'z',
  }}
  
data:extend{{
  type = 'tips-and-tricks-item',
  name = 'er:tips-header',
  category = const.tips.category_name,
  is_title = true,
  starting_status = "optional",
  order = '0',
  }}
