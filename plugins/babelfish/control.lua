-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local log         = elreq('erlib/lua/Log'       )().Logger  'PluginManagerLite'
local stop        = elreq('erlib/lua/Error'     )().Stopper 'PluginManagerLite'

-- local Stacktrace  = elreq('erlib/factorio/Stacktrace')()

local Table       = elreq('erlib/lua/Table'     )()
-- local Set         = elreq('erlib/lua/Set'       )()

-- local Verificate  = elreq('erlib/lua/Verificate')()
-- local verify      = Verificate.verify

-- local join_path   = elreq('erlib/factorio/Data/!init')().Path.join

-- local require     = _ENV. require -- keep a proper reference

local Hydra = require('__eradicators-library__/erlib/lua/Coding/Hydra')()


local script = EventManager .get_managed_script   'babelfish'
local import = PluginManager.make_relative_require'babelfish'

import '/ulocale'

local const = import '/const'

-- -------------------------------------------------------------------------- --
-- Savedata                                                                   --
-- -------------------------------------------------------------------------- --
local Savedata
PluginManager.manage_savedata  ('babelfish', function(_) Savedata = _ end)
PluginManager.manage_garbage   ('babelfish')
PluginManager.classify_savedata('babelfish', {

  get_pdata = function(self, e, pindex)
    local pdata = self.players[pindex or e.player_index]
       or Table.sget(self.players, {pindex or e.player_index}, {})
    return pdata, pdata.p end,
    
  })
  

-- -------------------------------------------------------------------------- --
-- Draft                                                                      --
-- -------------------------------------------------------------------------- --

  
script.on_event(defines.events.on_player_changed_position, function(e)
  print('Babelfish 1: ', serpent.block(Savedata))
  print('Babelfish 2: ', serpent.block(Savedata:get_pdata(e)))
  end)
  


script.on_event(defines.events.on_string_translated, function(e)
  say('Bablefish recieved translation: '.. Hydra.lines(e))
  end)


