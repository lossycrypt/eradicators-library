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
-- local log         = elreq('erlib/lua/Log'          )().Logger  'template'
-- local stop        = elreq('erlib/lua/Error'        )().Stopper 'template'
-- local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

-- local Verificate  = elreq('erlib/lua/Verificate'   )()
-- local verify      = Verificate.verify
-- local isType      = Verificate.isType

-- local Table       = elreq('erlib/lua/Table'        )()
-- local Array       = elreq('erlib/lua/Array'        )()
-- local Set         = elreq('erlib/lua/Set'          )()
-- local Filter      = elreq('erlib/lua/Filter'       )()
-- local Vector      = elreq('erlib/lua/Vector'       )()

-- local ntuples     = elreq('erlib/lua/Iter/ntuples' )()
-- local dpairs      = elreq('erlib/lua/Iter/dpairs'  )()
-- local sriapi      = elreq('erlib/lua/Iter/sriapi'  )()

-- local Setting     = elreq('erlib/factorio/Setting'   )()
-- local Player      = elreq('erlib/factorio/Player'    )()
-- local getp        = Player.get_event_player

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local script = EventManager .get_managed_script    'template'
-- local import = PluginManager.make_relative_require 'template'
-- local const  = import '/const'

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
-- local This = {}

-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- Savedata                                                                   --
-- -------------------------------------------------------------------------- --
-- local Savedata
-- local SavedataDefaults = {players = {}, version = 1}
-- PluginManager.manage_savedata  ('template', function(_) Savedata = _ end, SavedataDefaults)
-- PluginManager.manage_version   ('template')
-- PluginManager.manage_garbage   ('template')
-- PluginManager.classify_savedata('template', {
-- 
--   init_pdata = function(self, pindex)
--     return Table.set(self.players, {assert(pindex)}, {
--       p = game.players[pindex],
--       })
--     end,
-- 
--   get_pdata = function(self, e, pindex)
--     local pdata = assert(self.players[pindex or e.player_index])
--     return pdata, pdata.p end,
-- 
--   sget_pdata = function(self, e, pindex)
--     local pdata = self.players[pindex or e.player_index]
--             or self:init_pdata(pindex or e.player_index)
--     return pdata, pdata.p end,
-- 
--   del_pdata = function(self, e, pindex)
--     self.players[pindex or e.player_index] = nil
--     end,
--   
--   })
  
-- -------------------------------------------------------------------------- --
-- Events                                                                     --
-- -------------------------------------------------------------------------- --
