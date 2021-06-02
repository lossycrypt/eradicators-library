-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Localised string search for mods.
--
-- Babelfish is a caching translator for standard prototype localisations.
-- When it detects changes in the locale it starts a background task to 
-- translate all prototype names and descriptions. While this task is running
-- a small status indicator in the upper right corner informs each user of 
-- the current progress. Each language only needs to be translated once,
-- making the process instantaneous to most users even in multiplayer.
--
-- At the default network speed setting it takes about 10 seconds to fully
-- translate one language in vanilla factorio.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module Babelfish
-- @usage
--  -- settings.lua
--  erlib_enable_plugin('babelfish')
--  erlib_configure_plugin('babelfish', {
--    search_types = {'item_name', 'recipe_name'}
--    })
--
--  -- control.lua
--  remote.call('babelfish','find', player_index, word, options)

--[[ Annecdotes:

  I mean, like...srsly? The whole idea of sending network requests to get
  data that each client already has on disk is quite ridiculous ye know...

  ]]

--[[ Future:

  + Detect non-multiplayer language changes. Needs some fancy
    desync-unsafe voodoo magic (which is fine because SP doesn't desync...).
    I don't want to do regular polling just for this...
  
  ]]

--[[ Facts:
  
  + In Singleplayer on_string_translated is raised for all 
    requests from exactly one tick before.
  
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
local log         = elreq('erlib/lua/Log'          )().Logger  'Babelfish'
local stop        = elreq('erlib/lua/Error'        )().Stopper 'Babelfish'
local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

local Verificate  = elreq('erlib/lua/Verificate'   )()
local verify      = Verificate.verify
local isType      = Verificate.isType

local Table       = elreq('erlib/lua/Table'        )()
local String      = elreq('erlib/lua/String'       )()

local ntuples     = elreq('erlib/lua/Iter/ntuples' )()

local Setting     = elreq('erlib/factorio/Setting' )()
local Locale      = elreq('erlib/factorio/Locale'  )()

rawset(_ENV, 'No_Profiler_Commands', true)
local Profiler = require('__er-profiler-fork__/profiler.lua')

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local script = EventManager .get_managed_script    'babelfish'
local import = PluginManager.make_relative_require 'babelfish'
local const  = import '/const'
local ident  = serpent.line

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Babelfish = {}
-- local Dictionary = import 'methods/Dictionary_Naive'
-- local Dictionary = import 'methods/Dictionary_NoIdent'
local Dictionary = import 'methods/Dictionary_NoIdent_PacketPregen'

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
      dict = nil,
      -- last_recieve_tick = nil, -- on_string_translated
      next_request_tick = nil, -- on_player_language_changed
      })
    end,
  
  del_pdata = function(self, e, pindex)
    self.players[pindex or e.player_index] = nil
    end,
  
  get_dict = function(self, lcode)
    return assert(self.dicts[lcode]) end,
  
  sget_dict = function(self, lcode)
    return self.dicts[lcode]
        or Table.set(self.dicts, {lcode}, Dictionary(lcode))
    end,
  
  })

-- -------------------------------------------------------------------------- --
-- Conditional Events                                                         --
-- -------------------------------------------------------------------------- --

-- Sometimes an empty event is raised?
-- { migration_applied = false,
--   mod_changes = {},
--   mod_startup_settings_changed = false }
script.on_config(function(e)
  Dictionary.precompile()
  --
  if (not e) or
  ( (table_size(e.mod_changes) > 0)
    or e.migration_applied
    or e.mod_startup_settings_changed )
  then
    -- If any mod changes at all there is no way to know if and how
    -- the locale has changed. Thus we need to start from scratch.
    
    -- Table.overwrite(Savedata, Table.dcopy(DefaultSavedata))
    for _, dict in pairs(Savedata.dicts) do dict:update() end
    
    -- Savedata.dicts['internal'] = Dictionary.make_internal_names_dictionary()
    end
  Table.clear(Savedata.players)
  Babelfish.reclassify() -- probably redundant with on_load
  Babelfish.update_settings_cache()
  Babelfish.on_player_language_changed()
  end)

script.on_load(function(e)
  if not Savedata then return end -- on_load before on_config *again*...
  Babelfish.reclassify()
  Babelfish.update_handlers()
  end)

Babelfish.reclassify = function()
  for _, dict in ntuples(2, Savedata.dicts) do Dictionary.reclassify(dict) end
  end

-- Manages ALL event de/registration
-- must be ON_LOAD compatible!
Babelfish.update_handlers = function()
  local string_event   = defines.events.on_string_translated
  --
  local update_players = (not not Savedata.changed_players) or nil
  local update_dicts   = (not not Savedata.incomplete_dictionaries) or nil
  --
  -- Profiler.Start(false)
  -- Profiler.Start(true)
  -- Profiler.Stop()
  --
  if update_players then
    log:info('Translation suspended while waiting for language codes.')
    script.on_event   (string_event  , Babelfish.on_string_translated)
    script.on_nth_tick(            60, Babelfish.on_player_language_changed)
    script.on_nth_tick(             1, nil)
  elseif update_dicts then
    log:info('Translation started.')
    -- Send out translation requests.
    script.on_event   (string_event  , Babelfish.on_string_translated)
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
  }, function()
  local changed_players         = {}
  local incomplete_dictionaries = {}
  --
  for pindex, p in pairs(game.players) do
    if not p.connected then
      -- language must be re-evaluated on re-join
      Savedata:del_pdata(nil, pindex)
      log:debug('Player removed from game: ', p.name)
    else
      local pdata = Savedata:sget_pdata(nil, pindex)
      if (not pdata.dict) then
        table.insert(changed_players, pindex)
        if ((pdata.next_request_tick or 0) <= game.tick) then
          log:debug('Sent language code request to: ', pdata.p.name)
          assert(pdata.p.request_translation(const.lstring.language_code))
          pdata.next_request_tick = game.tick + const.network.rerequest_delay
          end
      else
        if pdata.dict:has_requests() then
          pdata.next_request_tick = game.tick
          incomplete_dictionaries[pdata.dict] = pdata -- need a player to request
          end
        end
      end
    end
  --
  Savedata.changed_players         = Table.nil_if_empty(changed_players)
  Savedata.incomplete_dictionaries = Table.nil_if_empty(incomplete_dictionaries)
  --
  if Savedata.incomplete_dictionaries then
    Savedata.bytes = 0
    Savedata.bytes_in_transit = 0
  else
    Savedata.bytes = nil
    Savedata.bytes_in_transit = nil
    end
  --
  Babelfish.update_handlers()
  --
  -- for _, pindex in ipairs(Savedata.changed_players or {}) do
      -- local pdata = Savedata:sget_pdata(nil, pindex)
    -- end
  end)



-- -------------------------------------------------------------------------- --
-- Request + Recieve                                                          --
-- -------------------------------------------------------------------------- --

local DO_PACKAGING = false
-- Packed     translation (full pyanodon): 1185ms
-- Non-Packed translation (full pyanodon):   90ms (13 times faster!)

local function get_profiler()
  return (not flag.IS_DEV_MODE) and ercfg.SKIP or (function(profiler)
    return function(msg) _ENV.log{'', msg, profiler}; profiler.restart() end
    end)(game.create_profiler())
  end


Babelfish.on_string_translated = function(e)
  --
  local lstring = e.localised_string
  local pdata = Savedata:sget_pdata(e)
  pdata.next_request_tick = e.tick
  --
  -- player language code
  if (#lstring == 1) and (lstring[1] == const.lstring.language_code[1]) then
    assertify(e.translated, 'Language code untranslated, wtf?')
    pdata.dict = Savedata:sget_dict(e.result)
    log:debug(("Player %s's language is %s (%s)."):format(
      pdata.p.name, pdata.dict.native_language_name, pdata.dict.language_code))
    Babelfish.on_player_language_changed()
  --
  -- babelfish packet
  elseif (lstring[2] == const.network.master_header) then
    assertify(e.translated, 'Untranslated babelfish packet!? ', e)
    -- packed request
    if lstring[3] == const.network.packet_header.packed_request then
      if pdata.dict then
        Savedata.bytes = Savedata.bytes +
          pdata.dict:on_string_translated(lstring, e.result)
        -- log:debug('Packet ok!')
      else
        log:debug('Packet recieved but player had not dictionary.', e)
        end
    else
      stop('Babelfish packet had unknown id.', e)
      end
  -- garbage (other mods)
  else
    log:debug('Ignoring unexpected translation event.')
    end
  --
  end


Babelfish.update_settings_cache = script.on_event(
  defines.events.on_runtime_mod_setting_changed,
  function()
    Savedata.max_bytes_per_tick =
      (game.is_multiplayer() or flag.IS_DEV_MODE)
      and (1024 / 60) * Setting.get_value('map', const.setting_name.network_rate)
      or math.huge
    Savedata.max_bytes_in_transit
      = Savedata.max_bytes_per_tick * const.network.transit_window * 60
    log:debug('Updated settings max_bytes_per_tick: ', Savedata.max_bytes_per_tick)
    log:debug('Updated settings max_bytes_in_transit: ', Savedata.max_bytes_in_transit)
    end)

  
-- on_nth_tick(1)
Babelfish.request_translations = function(e)
  -- To prevent lag-spikes during play always precompile
  -- as early as possible to make the load screen hide
  -- the spike.
  Dictionary.precompile()
  --
  -- Check if there's still work
  if 0 == table_size(Savedata.incomplete_dictionaries) then
    StatusIndicator.destroy_all()
    Babelfish.on_player_language_changed()
    return end
  --
  for dict, pdata in ntuples(2, Savedata.incomplete_dictionaries) do
    if not dict:has_requests() then
      Savedata.incomplete_dictionaries[dict] = nil
    else
      -- If a player hasn't answered in a while don't sent them more.
      -- if pdata.next_request_tick < (e.tick - const.network.rerequest_delay) then
        -- pdata.next_request_tick = e.tick + const.network.rerequest_delay
      -- elseif pdata.next_request_tick < e.tick then
        Savedata.bytes = Savedata.bytes + Savedata.max_bytes_per_tick
        -- print(e.tick, Savedata.bytes)
        -- Savedata.bytes can become negative after a large packet.
        if Savedata.bytes > 0 then
          for packet, bytes in dict:iter_packets() do
            pdata.p.request_translation(packet) -- todo: rate-limit
            Savedata.bytes = Savedata.bytes - bytes
            if Savedata.bytes <= 0 then return end
            end
          end
        -- end
      end
    end
  
  
  
  
  if true then return end -- LEGACY BELOW THIS
  
  --
  -- In Singleplayer all translation is done during the loading screen.
  -- Recalculated live to immediately reflect setting changes.

  --
  bytes_per_tick = 100000000000
  -- Profiler.Start(true)
  Profiler.Start(false)
  --
  Savedata.bytes = Savedata.bytes + bytes_per_tick
  -- V: Packaged (Hacked Garbage Code)
  if DO_PACKAGING then
    -- local profiler = game.create_profiler()
    for dict, p in ntuples(2, Savedata.incomplete_dictionaries) do
      repeat
        local bytes_before = Savedata.bytes
        local n, packet = 3, {'', const.network.packet_header}
        local function f (request)
          packet[n] = {'', request, '\0'}
          n = n + 1
          end
        Savedata.bytes = Savedata.bytes - dict:collect_packets(f, Savedata.bytes)
        if #packet > 2 then p.request_translation(packet) end
        until bytes_before == Savedata.bytes
      if not dict:has_requests() then
        Savedata.incomplete_dictionaries[dict] = nil
        end
      end
    -- _ENV.log{'', 'Full packed translation took: ', profiler}
    end
  -- V: Naive
  if not DO_PACKAGING then
    local profiler = game.create_profiler()
    for dict, p in ntuples(2, Savedata.incomplete_dictionaries) do
      Savedata.bytes = Savedata.bytes - dict:dispatch_requests(p, Savedata.bytes)
      if not dict:has_requests() then
        Savedata.incomplete_dictionaries[dict] = nil
        end
      end    
    _ENV.log{'', 'Full non-packed translation took: ', profiler}
    end
  assert(Savedata.bytes >= 0)
  --

  end 
  
-- -------------------------------------------------------------------------- --
-- Status Indicator                                                           --
-- -------------------------------------------------------------------------- --
Babelfish.update_status_indicators = function(e)
  -- Tooltip shows progress for all languages.
  local tooltip = {}
  for dict in pairs(Savedata.incomplete_dictionaries) do
    table.insert(tooltip, 
      ('\n%3s%% %s'):format(dict:get_percentage(), dict.native_language_name))
    end
  tooltip = {
    'babelfish.status-indicator-tooltip-header',
    Locale.merge(table.unpack(tooltip))
    }
  -- Sprite button shows progress for the owning player.
  for _, p in pairs(game.connected_players) do
    local pdata = Savedata:get_pdata(nil, p.index)
    StatusIndicator.update(p, pdata.dict:get_percentage(), tooltip)
    end
  end


-- -------------------------------------------------------------------------- --
-- Remote + Documentation                                                     --
-- -------------------------------------------------------------------------- --
  
--------------------------------------------------------------------------------
-- Startup.  
-- @section
--------------------------------------------------------------------------------

----------
-- Babelfish must be activated and configured before use by calling the
-- two public global functions explained in the example. Otherwise it
-- will not load at all. This configuration is global for all mods.
-- This must be done in __settings.lua__.
--
-- You must first activate Babelfish and then add at least one
-- @{Babelfish.SearchType|SearchType}.
--
-- @usage
--  
--  erlib_enable_plugin('babelfish')
--
--  --This *ADDS* several types. Types can not be removed once added by any mod.
--  erlib_configure_plugin('babelfish', {
--    search_types = {'item_name', 'recipe_name'}
--    })
--
-- @table HowToActivateBabelfish
do end
  
--------------------------------------------------------------------------------
-- Remote Interface Types.
-- @section
--------------------------------------------------------------------------------

----------
-- What to search. One of the following strings. This is also the
-- order in which translation occurs.
--
--    'item_name'      , 'item_description'
--    'fluid_name'     , 'fluid_description'
--    'recipe_name'    , 'recipe_description'
--    'technology_name', 'technology_description'
--    'equipment_name' , 'equipment_description'
--    'tile_name'      , 'tile_description'
--    'entity_name'    , 'entity_description'
--
-- @table Babelfish.SearchType

----------
-- Identifies a language between different Babelfish function calls.
-- Storing this in your global data will likely produce unexpected results.
-- It's best to always retrieve this shortly before usage.
--
-- @table Babelfish.LanguageCode
  
--------------------------------------------------------------------------------
-- Remote Interface.  
-- @section
--------------------------------------------------------------------------------

local Remote = {}
remote.add_interface(const.remote.interface_name, Remote)

----------
-- Reports if the given types are completely translated yet.
--
-- Does the same internal checks as @{Babelfish.find_prototype_names} so
-- usually you won't need to call this seperately.
--
-- @tparam player_index|LanguageCode pindex
-- A language code should only be used if your mod needs to
-- allow a player to search in a locale different from their own.
-- @tparam string|DenseArray types One or more @{Babelfish.SearchType|SearchTypes}.
--
-- @treturn boolean If all of the given types are searchable.
--
-- @function Babelfish.can_find
function Remote.can_find(pindex, types)
  return (Remote.find_prototype_names(pindex, types, '', {limit=0})) end

----------
-- Given a user input, finds prototype names.
-- Can search the localised name and description of all common prototypes
-- to deliver a native search experience.
--
-- Translation is granular per @{Babelfish.SearchType|SearchType},
-- so users can start searching for i.e. recipe names even if item names
-- are still being translated.
--
-- Prototypes with unlocalised strings (i.e. "unknown-key:*")
-- are not included in the search.
--
-- @tparam player_index|LanguageCode pindex
-- A language code should only be used if your mod needs to
-- allow a player to search in a locale different from their own.
-- @tparam string|DenseArray types One or more @{Babelfish.SearchType|SearchTypes}.
-- @tparam string word The user input.
-- @param options (@{table})
-- @tparam[opt=inf] Integer options.limit Search will abort after this many
-- hits and return the (partial) result.
-- @tparam[opt=plain] string options.mode `'plain'`, `'fuzzy'` or `'lua'`.
-- Plain and fuzzy modes should work fine with unicode input.
-- Lua mode will return an empty search result if "word" is not
-- a @{string.find} compatible pattern. 
-- 
-- @usage
-- 
--   -- First lets make a shortcut.
--   local babelfind = (function(c) return function(...)
--     return c('babelfish','find_prototype_names',...)
--     end end)(remote.call)
--   
--   -- Now lets try something. For demonstration purposes I'm using a player
--   -- with a German locale.
--   local ok, results
--     = babelfind(game.player.index, {'item_name','recipe_name'},'Kupfer')
--   if ok then print(serpent.block(results)) end
--   
--   > {
--   >   item_name = {
--   >     ["copper-cable"] = true,
--   >     ["copper-ore"] = true,
--   >     ["copper-plate"] = true
--   >   },
--   >   recipe_name = {
--   >     ["copper-cable"] = true,
--   >     ["copper-plate"] = true
--   >   }
--   > }
-- 
-- @treturn boolean|nil  
--
--   @{nil} means: The requested language is not available. Either you used
--   an outdated LanguageCode or the player has only just connected and isn't
--   identified yet. No search result is returned.  
--
--   @{false} means: Babelfish is still translating some or all of the requested
--   SearchTypes. A best effort search result is included but likely to be
--   incomplete. It is recommended to try again after translation is complete.  
--
--   @{true} means: No problems occured.  
--  
-- @treturn table|nil The search result. A table mapping each requested
-- SearchType to a @{Types.set|set} of prototype names. 
--
-- @function Babelfish.find_prototype_names
function Remote.find_prototype_names(pindex, types, word, options)
  -- The other mod might send the index of an offline player!
  local dict
  if isType.NaturalNumber(pindex) then
    assertify(game.players[pindex], 'No player with given index: ', pindex)
    dict = Savedata:sget_pdata(nil, pindex).dict
  else
    assertify(const.native_language_name[pindex], 'Invalid language code: ', pindex)
    dict = Savedata.dicts[pindex]
    end
  if not dict then return nil, nil end -- while waiting for language_code
  return dict:find(Table.plural(types), word, options or {}) end

----------
-- Retrieves the language code of a player.
-- Only @{FOBJ LuaPlayer.connected|connected} players have a code, and
-- there is a delay of one "ping" between connection and code
-- assignment.
-- 
-- @tparam NaturalNumber pindex A @{FOBJ LuaPlayer.index}.
-- @return The @{Babelfish.LanguageCode|LanguageCode} or @{nil}.
--
-- @function Babelfish.get_player_language_code
function Remote.get_player_language_code(pindex)
  verify(pindex, 'NaturalNumber', 'Babelfish: Invalid player index')
  assertify(game.players[pindex], 'No player with given index: ', pindex)
  return Savedata:sget_pdata(nil, pindex).language_code or nil
  end
  
----------
-- Retrieves translation percentage of all seen languages.
-- This is the same data that the built-in status indicator uses.
-- Includes only languages that have been seen on this map at least once.
-- 
-- __Note:__ This is the total percentage. Prioritized SearchType are
-- usually available much earlier than 100%. Use @{Babelfish.can_find}.
-- 
-- @treturn table A mapping (@{Babelfish.LanguageCode|LanguageCode} → @{NaturalNumber})
-- where the number is between 0 and 100 inclusive.
-- 
-- @function Babelfish.get_translation_percentages
function Remote.get_translation_percentages()
  local r = {}
  for code, dict in ntuples(2, Savedata.dicts) do
    r[code] = dict:get_percentage()
    end
  return r end

----------
-- Triggers an internal update.
--
-- This is meant to be used to circumvent the hard engine limitation of
-- no events being raised in Singleplayer when the locale changes but
-- nothing else changed.
--
-- This can also be triggered by the commands `'/babelfish update'` (sp only)
-- and `'/babelfish reset'` (admin only) respectively.
--
-- @tparam[opt=false] boolean reset Completely resets all translations
-- instead of just performing a normal update.
--
-- @function Babelfish.force_update
function Remote.force_update(force)
  if (force == true) then
    script.get_event_handler('on_configuration_changed')()
  else
    Table.clear(Savedata.players)
    Babelfish.on_player_language_changed()
    end
  end
  
  
local subcommands = {
  update = function(e, pdata, p)
    if game.is_multiplayer() then
      p.print {'babelfish.command-only-in-singleplayer'}
    else
      Remote.force_update()
      return true end
    end,
  reset = function(e, pdata, p)
    if game.is_multiplayer() and not p.admin then
      p.print {'babelfish.command-only-by-admin'}
    else
      Remote.force_update(true)
      return true end
    end,
  dump = function(e, pdata, p)
    for _, dict in pairs(Savedata.dicts) do
      dict:dump_statistics_to_console()
      end
    end,
  }
script.on_event(defines.events.on_console_command, function(e)
  if (e.command == 'babelfish') then
    local pdata, p = Savedata:sget_pdata(e)
    local f = subcommands[e.parameters]
    if f then
      if f(e, pdata, p) then
        p.print {'babelfish.command-confirm'}
        end
    else
      p.print{'babelfish.unknown-command'}
      end
    end
  end)

  
-- -------------------------------------------------------------------------- --
-- Draft                                                                      --
-- -------------------------------------------------------------------------- --
