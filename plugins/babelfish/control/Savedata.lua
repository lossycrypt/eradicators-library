-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------------------------------------
-- Babelfish.
-- @module Babelfish

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
local log         = elreq('erlib/lua/Log'          )().Logger  'babelfish'
local stop        = elreq('erlib/lua/Error'        )().Stopper 'babelfish'
local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

-- local Verificate  = elreq('erlib/lua/Verificate'   )()
-- local verify      = Verificate.verify
-- local isType      = Verificate.isType

local Table       = elreq('erlib/lua/Table'        )()
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
-- local script = EventManager .get_managed_script    'babelfish'
local import = PluginManager.make_relative_require 'babelfish'
local const  = import '/const'

local Dictionary       = import '/control/Dictionary'


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
local Savedata, DefaultSavedata = nil, {
  players = {}, dicts = {}, packets = {}, version = const.version.savedata,
  }
PluginManager.manage_savedata  ('babelfish', function(_) Savedata = _ end, DefaultSavedata)
PluginManager.manage_garbage   ('babelfish')
PluginManager.classify_savedata('babelfish', {

-- -------------------------------------------------------------------------- --
-- pdata

  get_pdata = function(self, e, pindex)
    local pdata = assert(self.players[pindex or e.player_index], 'Missing pdata.')
    return pdata, pdata.p end,

  sget_pdata = function(self, e, pindex)
    local pdata = self.players[assert(pindex or e.player_index, 'Missing pindex')]
               or self:init_pdata(pindex or e.player_index)
    return pdata, pdata.p end,
  
  init_pdata = function(self, pindex)
    return Table.set(self.players, {pindex}, {
      p = game.players[pindex],
      --
      dict           = nil ,
      is_lcode_dirty = true,
      })
    end,
  
  del_pdata = function(self, e, pindex)
    self.players[pindex or e.player_index] = nil
    end,
 
-- -------------------------------------------------------------------------- --
-- pdata extended
  
  -- flag player lcode as outdated
  set_pdata_lcode_dirty = function(self, e, pindex, true_or_nil)
    local pdata = self:get_pdata(e, pindex)
    pdata.is_lcode_dirty = true_or_nil
    return nil end,
    
  -- set new lcode for player + raise events
  set_pdata_lcode = function(self, e, pindex, lcode)
    assertify(const.native_language_name[lcode], 'Invalid language code: ', lcode)
    --
    local pdata, p = self:get_pdata(e, pindex)
    self:set_pdata_lcode_dirty(e, pindex, nil)
    pdata.dict = self:sget_dict(lcode)
    --
    log:debugf("Player %s's language set to %s (%s).",
      p.name, Savedata:get_dict_lname(pdata.dict), lcode)
    end,
  
-- -------------------------------------------------------------------------- --
-- dict
  
  sget_dict = function(self, lcode)
    return self.dicts[lcode]
        or Table.set(self.dicts, {lcode}, Dictionary())
    end,
   
  get_dict_lcode = function(self, dict) -- language_code
    -- during finalizer -> update() the dict has no code yet.
    return Table.find(self.dicts, dict)
    end,
    
  get_dict_lname = function(self, dict) -- native_language_name
    return const.native_language_name[self:get_dict_lcode(dict)]
    end,
    
-- -------------------------------------------------------------------------- --
-- bandwidth
    
  set_byte_allowance = function(self, bytes)
    self.byte_allowance = bytes -- set to nil when not translating
    end, 
   
  get_byte_allowance = function(self)
    return self.byte_allowance or 0
    end,

  substract_byte_allowance = function(self, bytes)
    self.byte_allowance = (self.byte_allowance or 0) - bytes
    end,
    
  purge_packets = function(self)
    self.packets = {}
    end,
      
-- -------------------------------------------------------------------------- --
-- event condition
  
  -- Array of players who need lcode updates.
  get_lcode_requesters = function(self)
    local r = Table.map(
      Table.values(self.players),
      function(pdata) if pdata.is_lcode_dirty then return pdata.p end end,
      {})
    if #r > 0 then return r end
    return nil end,

  -- The dictionary that is currently being translated.
  get_active_dict = function(self)
    for _, pdata in pairs(self.players) do
      if  pdata.dict
      and pdata.dict:has_requests()
      and pdata.p.connected
      then
        return pdata.dict, pdata.p
        end
      end
    return nil end,
    
-- -------------------------------------------------------------------------- --
-- repair

  -- Delete everything that's not a default value.
  clear_volatile_data = function(self)
    Table.clear(self, Table.keys(DefaultSavedata))
    end,
  
  reset_to_default = function(self)
    Table.overwrite(self, Table.dcopy(DefaultSavedata))
    end,
  
  })

  