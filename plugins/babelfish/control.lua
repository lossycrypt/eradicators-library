--[[

  I mean, like...srsly? The whole idea of sending network requests to get
  data that each client already has on disk is quite ridiculous ye know...

  ]]

--[[ Future: 

    +Detect non-multiplayer language changes. Needs some fancy
    desync-unsafe voodoo magic (which is fine because SP doesn't desync...).

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
local log         = elreq('erlib/lua/Log'       )().Logger  'Babelfish'
local stop        = elreq('erlib/lua/Error'     )().Stopper 'Babelfish'

-- local Stacktrace  = elreq('erlib/factorio/Stacktrace')()

local Table       = elreq('erlib/lua/Table'     )()
local Setting       = elreq('erlib/factorio/Setting'     )()
-- local Cache       = elreq('erlib/factorio/Cache'     )()
-- local Set         = elreq('erlib/lua/Set'       )()

local Verificate  = elreq('erlib/lua/Verificate')()
local verify      = Verificate.verify

-- local join_path   = elreq('erlib/factorio/Data/!init')().Path.join

-- local require     = _ENV. require -- keep a proper reference

local Setting = elreq('erlib/factorio/Setting')()

local Hydra = elreq('erlib/lua/Coding/Hydra')()

local ntuples = elreq('erlib/lua/Iter/ntuples')()

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local script = EventManager .get_managed_script   'babelfish'
local import = PluginManager.make_relative_require'babelfish'
local const  = import '/const'
local ident  = serpent.line

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Babelfish = {}
local Dictionary = import 'methods/Dictionary'

local StatusIndicator = import 'methods/StatusIndicator'

-- -------------------------------------------------------------------------- --
-- Savedata                                                                   --
-- -------------------------------------------------------------------------- --
local Savedata, DefaultSavedata = nil, {
  players = {}, dicts = {}
  }
PluginManager.manage_savedata  ('babelfish', function(_) Savedata = _ end, DefaultSavedata)
PluginManager.manage_garbage   ('babelfish')
PluginManager.classify_savedata('babelfish', {

  get_pdata = function(self, e, pindex)
    return assert(self.players[pindex or e.player_index])
    end,

  sget_pdata = function(self, e, pindex)
    local pdata = self.players[pindex or e.player_index]
            or self:init_pdata(pindex or e.player_index)
    return pdata, pdata.p end,
  
  init_pdata = function(self, pindex)
    return Table.set(self.players, {pindex}, {
      p = game.players[pindex],
      language_code = nil,
      dict = nil,
      })
    end,
  
  del_pdata = function(self, e, pindex)
    self.players[pindex or e.player_index] = nil
    end,
  
  get_dict = function(self, lcode)
    return assert(self.dicts[lcode]) end,
  
  sget_dict = function(self, lcode)
    return (self.dicts or Table.set(self,{'dicts'},{}))[lcode]
        or Table.set(self.dicts, {lcode}, Dictionary(lcode))
    end,
  
  })
  
-- -------------------------------------------------------------------------- --
-- Conditional Events                                                         --
-- -------------------------------------------------------------------------- --

-- If any mod changes at all there is no way to know if and how
-- the locale has changed. Thus we need to start from scratch.
script.on_config(function(e)
  Table.overwrite(Savedata, Table.dcopy(DefaultSavedata))
  Babelfish.on_player_language_changed()
  end)
  
script.on_load(function(e)
  for _, dict in ntuples(2, Savedata.dicts) do
    Dictionary.reclassify(dict)
    end
  Babelfish.update_handlers()
  end)

-- Manages ALL event de/registration
-- must be ON_LOAD compatible!
Babelfish.update_handlers = function()
  local string_event   = defines.events.on_string_translated
  --
  local update_players = (not not Savedata.changed_players) or nil
  local update_dicts   = (not not Savedata.incomplete_dictionaries) or nil
  --
  if update_players then
    log:debug('Translation suspended while waiting for language codes.')
    script.on_event   (string_event  , Babelfish.on_recieve_language_code)
    script.on_nth_tick(            60, Babelfish.on_player_language_changed)
    script.on_nth_tick(             1, nil)
  elseif update_dicts then
    log:debug('Translation started.')
    -- Send out translation requests.
    script.on_event   (string_event  , Babelfish.on_recieve_translation)
    script.on_nth_tick(            60, Babelfish.update_status_indicators)
    script.on_nth_tick(             1, Babelfish.request_translations)
  else
    log:info('All translations finished.')
    -- Sleep while nothing is happening.
    script.on_event   (string_event  , nil)
    script.on_nth_tick(            60, nil)
    script.on_nth_tick(             1, nil)
    end
  end
  
  
-- -------------------------------------------------------------------------- --
-- Player Language                                                            --
-- -------------------------------------------------------------------------- --
Babelfish.on_player_language_changed = script.on_event({
  -- Always watch for potential language changes.
  defines.events. on_player_left_game  ,
  defines.events. on_player_created    ,
  defines.events. on_player_joined_game,
  defines.events. on_player_removed    ,
  }, function(e)
  local changed_players         = {}
  local incomplete_dictionaries = {}
  --
  for pindex, p in pairs(game.players) do
    if not p.connected then
      -- language must be re-evaluated on re-join
      Savedata:del_pdata(nil, pindex)
    else
      local pdata = Savedata:sget_pdata(nil, pindex)
      if (not pdata.language_code) then
        if ((pdata.next_request_tick or 0) <= game.tick) then
          assert(p.request_translation(const.lstring.language_code))
          pdata.next_request_tick = game.tick + 30
          table.insert(changed_players, pindex)
          end
      else
        local dict = Savedata:sget_dict(pdata.language_code)
        pdata.dict = dict -- link
        if dict:needs_translation() then
          incomplete_dictionaries[dict] = p -- need a player to request
          end
        end
      end
    end
  --
  Savedata.changed_players         = Table.nil_if_empty(changed_players)
  Savedata.incomplete_dictionaries = Table.nil_if_empty(incomplete_dictionaries)
  --
  Babelfish.update_handlers()
  end)

-- Wait for the requested language codes.  
Babelfish.on_recieve_language_code = 
  (function(f) return function(e) return e.translated and f(e) end end)
  (function(e)
    if (#e.localised_string == 1)
    and (e.localised_string[1] == const.lstring.language_code[1])
    then
      local pdata = Savedata:sget_pdata(e)
      pdata.language_code = e.result
      pdata.next_request_tick = nil
      Babelfish.on_player_language_changed()
      log:debug(("Player %s's language is %s (%s)."):format(
        pdata.p.name, const.native_language_name[pdata.language_code], pdata.language_code))
      end
  end)

-- -------------------------------------------------------------------------- --
-- Reqest + Recieve                                                           --
-- -------------------------------------------------------------------------- --
  
Babelfish.on_recieve_translation = 
  -- (function(f) return function(e) if not e.translated then stop(e) end f(e) end end)
  -- (function(f) return function(e) return e.translated and f(e) end end)
  (function(e)
    -- say('Bablefish recieved translation: '.. Hydra.lines(e))
    assert(Savedata:get_pdata(e).dict)
    
    -- Savedata
      -- :get_dict(assert(Savedata:get_pdata(e).language_code))
      :push_translation(e.localised_string, e.translated and e.result)
  end)


Babelfish.request_translations = function(e) 
  -- Babelfish.update_status_gui()
  -- print(Hydra.lines(Savedata.dicts,{indentlevel = 4}))
  
  local allowed_bytes =
    (game.is_multiplayer() or flag.IS_DEV_MODE)
    and (1024 / 60) * Setting.get_value('map', const.setting.network_rate)
    or math.huge
  
  for dict, p in ntuples(2, Savedata.incomplete_dictionaries) do
    local count = dict:dispatch_requests(p, allowed_bytes)
    allowed_bytes = allowed_bytes - count
    -- print(count, dict:get_percentage(), '%')
    if not dict:needs_translation() then
      Savedata.incomplete_dictionaries[dict] = nil
      -- print(Hydra.lines(dict,{indentlevel=3}))
      end
    if allowed_bytes <= 0 then break end
    end
    
  if 0 == table_size(Savedata.incomplete_dictionaries) then
    StatusIndicator.destroy_all()
    Babelfish.on_player_language_changed() --future: make specialized...
    end
    
  -- if e.tick % 60 == 0 then
    
    -- update cached dictionary status
    -- dict:compress_requests()
    -- end
  end 


Babelfish.update_status_indicators = function(e)
  local tooltip = 'Babelfish is translating...'
  for dict in pairs(Savedata.incomplete_dictionaries) do
    tooltip = tooltip ..
      ('\n%3s%% %s')
      :format(dict:get_percentage(), dict.native_language_name)
    end
  for _, p in pairs(game.connected_players) do
    local pdata = Savedata:get_pdata(nil, p.index)
    local percent = pdata.dict:get_percentage()
    StatusIndicator.update(p, percent, tooltip)
    end
  end

  
script.on_event(defines.events.on_console_command, function(e)
  if e.command == 'babelfish' then
    if game.is_multiplayer() then return end
    print(Hydra.lines(
      {Savedata:get_pdata(e).dict:find(
        table.unpack{load('return '..e.parameters)()}
        )}
      ,{indentlevel=3}))
    end
  end)