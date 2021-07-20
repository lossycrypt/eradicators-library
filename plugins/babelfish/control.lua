-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Localised string search for mods.
--
-- Babelfish is a caching translator for standard prototype localisations.
-- When it detects changes in the locale it starts a background task to 
-- translate all prototype names and descriptions. In Singleplayer this
-- process happens during the loading screen and is invisible to the player.
-- In Multiplayer translation is done gradually in on_tick to prevent
-- network congestion. Each language only needs to be translated once,
-- so even in Multiplayer the process is instant for most users.
--
-- While translation is running a small status indicator in
-- the upper right corner informs each user of the _approximate_ progress. 
-- However there is no such progress information on the API as the real
-- progress is much more complex and prioritized SearchTypes like
-- `"item_name`" may already be completely translated despite the indicator
-- showing i.e. "10%".
--
-- @{Introduction.DevelopmentStatus|Module Status}: Polishing.
--
-- @module Babelfish

--[[ Annecdotes:

  I mean, like...srsly? The whole idea of sending network requests to get
  data that each client already has on disk is quite ridiculous ye know...

  ]]

--[[ Future:

  + Detect non-multiplayer language changes. Needs some fancy
    desync-unsafe voodoo magic (which is fine because SP doesn't desync...).
    I don't want to do regular polling just for this...
  
  ? Needs engine support.
    Detect non-headless multiplayer host. If there's only 
    one player use instant-translation before others can join.
  
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
-- Eradicators Library                                                        --
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

-- rawset(_ENV, 'No_Profiler_Commands', true)
-- local Profiler = require('__er-profiler-fork__/profiler.lua')

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local script = EventManager .get_managed_script    'babelfish'
local import = PluginManager.make_relative_require 'babelfish'
local const  = import '/const'

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Babelfish = {}
-- local Dictionary = import 'methods/Dictionary_Naive'
-- local Dictionary = import 'methods/Dictionary_NoIdent'
local Dictionary = import 'methods/Dictionary_NoIdent_PacketPregen'

local StatusIndicator = import 'methods/StatusIndicator'

script.generate_event_name('on_babelfish_translation_state_changed') -- before Demo

-- local Demo = import 'demo/control'

local Remote = {}
remote.add_interface(const.remote.interface_name, Remote)

local Deprecated = {} -- disabled Remote methods


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
  
  -- get_dict = function(self, lcode)
    -- return assertify(self.dicts[lcode], 'No dict with that code: ', lcode) end,
  
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
  --
  Savedata.version = 1 -- reserved for future use
  --
  Dictionary.precompile()
  --
  if (not e) or
  ( (table_size(e.mod_changes) > 0)
    or e.migration_applied
    or e.mod_startup_settings_changed )
  then
    for _, dict in pairs(Savedata.dicts) do
      dict:update()
      -- There are too many edge cases around half-translated dictionaries
      -- and/or change in requested search types to reasonably detect 
      -- if there was a change or not. So this must always be raised.
      Babelfish.raise_on_translation_state_changed(dict)
      end
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
    -- Must always be reset to 0 to prevent
    -- physical packet loss from permamently
    -- messing up the numbers.
    --
    -- How many bytes will be sent next tick
    Savedata.bytes = 0
    -- How many bytes are currently requested but not translated yet (estimate)
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
    Babelfish.raise_on_translation_state_changed(nil, e.player_index)
  --
  -- babelfish packet
  elseif (lstring[2] == const.network.master_header) then
    assertify(e.translated, 'Untranslated babelfish packet!? ', e)
    -- packed request
    if lstring[3] == const.network.packet_header.packed_request then
      if pdata.dict then
        local bytes_estimate, packet_bytes, has_state_changed
          = pdata.dict:on_string_translated(lstring, e.result)
        Table['+='](Savedata, {'bytes'}, (bytes_estimate - #e.result))
        Table['+='](Savedata, {'bytes_in_transit'}, -packet_bytes)
        -- log:debug('Packet ok!')
        if has_state_changed then
          Babelfish.raise_on_translation_state_changed(pdata.dict)
          end
      else
        log:debug('Packet recieved but player had not dictionary.', e)
        end
    else
      stop('Babelfish packet had unknown id.', e)
      end
  -- garbage (other mods)
  else
    log:debug('Ignoring unexpected translation event.')
    -- log:debug(('Ignoring unexpected translation event. (Lenght: %s, Start: %s'):format(#e.result, e.result:sub(1,10)))
    end
  --
  end


Babelfish.update_settings_cache = script.on_event(
  defines.events.on_runtime_mod_setting_changed,
  function()
    if (not game.is_multiplayer())
    and Setting.get_value('map', const.setting_name.sp_instant_translation)
    then
      Savedata.max_bytes_per_tick
        = math.huge
    else
      Savedata.max_bytes_per_tick
        = (1024 / 60) * Setting.get_value('map', const.setting_name.network_rate)
      end
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
        Savedata.bytes = Savedata.bytes + Savedata.max_bytes_per_tick
        -- Savedata.bytes can become negative after a large packet.
        if Savedata.bytes > 0 then
          for packet, packet_bytes in dict:iter_packets(e.tick) do
            pdata.p.request_translation(packet)
            Table['+='](Savedata, {'bytes'           }, -packet_bytes)
            Table['+='](Savedata, {'bytes_in_transit'},  packet_bytes)
            if Savedata.bytes_in_transit >= Savedata.max_bytes_in_transit then
              -- Reduce request rate to at most 1 packet per tick if 
              -- too many requests are unanswered.
              log:info('Player "', pdata.p.name, '" is timing out.')
              return end
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
  local tooltip = {'', {'babelfish.translation-in-progress'} }
  for dict in pairs(Savedata.incomplete_dictionaries) do
    table.insert(tooltip, 
      ('\n%3s%% %s'):format(dict:get_percentage(), dict.native_language_name))
    end
  Locale.compress(tooltip)
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
-- Concepts.
-- @section
--------------------------------------------------------------------------------
 
----------
-- Babelfish must be activated before use by calling the global function 
-- `erlib_enable_plugin` in __settings.lua__.
-- You must also activate at __at least one__ @{Babelfish.SearchType|SearchType}
-- by passing an array of search types (see the code box below).
-- Once a search type has been activated by any mod it can not be deactivated
-- again. You can call `erlib_enable_plugin` repeatedly to add more search 
-- types later.
--
--    erlib_enable_plugin('babelfish', {
--      search_types = {'item_name', 'fluid_name', 'recipe_name'}
--      })
--
-- The Demo-Gui must be activated seperately. It should only be activated
-- during development.
--
--    erlib_enable_plugin('babelfish-demo')
--
-- @table HowToActivateBabelfish
do end

----------
-- What to search. One of the following strings. __This is also the
-- order in which translation occurs.__ Once translation for a type
-- is complete it can be fully searched, regardless of the translation
-- status of the other types.
--
--    "item_name"          , "item_description"      ,
--    "fluid_name"         , "fluid_description"     ,
--    "recipe_name"        , "recipe_description"    ,
--    "technology_name"    , "technology_description",
--    "equipment_name"     , "equipment_description" ,
--    "tile_name"          , "tile_description"      ,
--    "entity_name"        , "entity_description"    ,
--    "virtual_signal_name",
--
-- @table Babelfish.SearchType
do end

-- -------
-- Identifies a language between different Babelfish function calls.
-- Storing this in your global data will likely produce unexpected results.
-- It's best to always retrieve this shortly before usage.
--
-- Only @{FOBJ LuaPlayer.connected|connected} players have a code, and
-- there is a delay of one "ping" between connection and code
-- assignment.
--
-- The special string `'internal'` can be used to ignore the locale and
-- search prototype names directly.
--
-- @table Babelfish.LanguageCode
do end


----------
-- Babelfish built-in sprites. Can be used to decorate mod guis.
-- All icons are 256x256 pixels with 4 mip-map levels.   
--
-- @{FAPI Concepts.SpritePath s}:
-- 
--     "er:babelfish-icon-default"
--     "er:babelfish-icon-green"
--     "er:babelfish-icon-red"
-- 
-- @table Sprites
do end
  
  
--------------------------------------------------------------------------------
-- Remote Interface.  
-- @section
--------------------------------------------------------------------------------

----------
-- The remote interface is named `"babelfish`".
-- @table RemoteInterfaceName
do end

  
----------
-- Reports if all of the given types are completely translated yet.
--
-- Uses the same parameters and does the same internal checks as 
-- @{Babelfish.find_prototype_names} but does not conduct a search,
-- and only returns the status code.
--
-- @param pindex
-- @param types
--
-- @treturn boolean|nil The status code.
--
-- @function Babelfish.can_translate
function Remote.can_translate(pindex, types, options)
  options = options or {}
  options.limit = 0
  return (Remote.find_prototype_names(pindex, types, '', options)) end
  

----------
-- Given a user input, finds prototype names.
-- Can search the localised name and description of all common prototypes
-- to deliver a native search experience.
-- Translation is granular per @{Babelfish.SearchType|SearchType}.
--
-- All searches are conducted in __lower-case__ (as far as @{string.lower}
-- works in that language). In the SearchType order given,
-- and in prototype `order` specific order.
--
-- The search result is identical to vanilla search even for unlocalised
-- names and descriptions (i.e. "Unknown Key:").
-- 
-- With some intentional exceptions:  
-- 1) If `word` is an exact prototype name (i.e. "iron-plate") 
-- that prototype will _additionally_ be included in the search result.  
-- 2) Babelfish does not filter prototypes. The serch result includes names
-- of all matching prototypes including hidden items, void recipes, etc.  
-- 3) Babelfish understands unicode language spaces (vanilla does _not_).
-- 
-- @usage
-- 
--   -- First lets make a shortcut.
--   local babelfind = (function(c) return function(...)
--     return c('babelfish', 'find_prototype_names', ...)
--     end end)(remote.call)
--   
--   -- For demonstration purposes let's use a player with a German locale.
--   local ok, results
--     = babelfind(game.player.index, {'item_name', 'recipe_name'}, 'Kupfer')
--   if ok then print(serpent.block(results)) end
--   
--   > {
--   >   item_name = {
--   >     ["copper-cable"] = true,
--   >     ["copper-ore"  ] = true,
--   >     ["copper-plate"] = true
--   >   },
--   >   recipe_name = {
--   >     ["copper-cable"] = true,
--   >     ["copper-plate"] = true
--   >   }
--   > }
--
-- @tparam NaturalNumber pindex A @{FOBJ LuaPlayer.index}.
-- @tparam string|DenseArray types One or more @{Babelfish.SearchType|SearchTypes}.
-- @tparam string word The user input. Interpreted according to the users chosen
-- search mode: plaintext, fuzzy or lua pattern (per-player mod setting).
-- For best performance it is
-- recommended to not search for strings shorter than length 2.
-- @param options (@{table})
-- @tparam[opt=inf] Integer options.limit Search will abort after this many
-- hits and return the (partial) result.
-- 
-- @treturn boolean|nil The status code.  
--
--   @{nil} means: The language for that player has not been detected yet.
--   This should hardly ever happen in reality. Just try again a second later.
--
--   @{false} means: Babelfish is still translating some or all of the requested
--   SearchTypes. A best-effort search result is included but likely to be
--   incomplete. It is recommended to try again after translation is complete.  
--   You can show `{'babelfish.translation-in-progress'}` to the player.
--
--   @{true} means: No problems occured.  
--
-- @treturn table|nil The search result. A table mapping each requested
-- SearchType to a @{Types.set|set} of prototype names. 
--
-- @function Babelfish.find_prototype_names
function Remote.find_prototype_names(pindex, types, word, options)
  -- The other mod might send the index of an offline player!
  verify(pindex, 'NaturalNumber', 'No player with given index: ', pindex)
  assertify(game.players[pindex], 'No player with given index: ', pindex)
  verify(options, 'tbl|nil', 'Invalid options.') --future: remove redundant verify
  local dict = Savedata:sget_pdata(nil, pindex).dict
  --
  options = options or {}
  options.mode = Setting.get_value(pindex, const.setting_name.string_match_type)
  --
  if options.language_code then
    stop('Deprecated') -- @future: mod setting? mini-gui?
    if options.language_code == 'internal' then
      -- Only created if anybody ever asks for it.
      dict = Savedata:sget_dict('internal')
    else
      dict = Savedata.dicts[options.language_code]
      end
    end
  --
  if not dict then return nil, nil end -- while waiting for language_code
  --
  return dict:find(Table.plural(types), word, options or {}) end

  
----------
-- Retrieves the localised name or description of a single prototype.
--
-- @tparam NaturalNumber pindex A @{FOBJ LuaPlayer.index}.
-- @tparam string type A @{Babelfish.SearchType}.
-- @tparam string name A prototype name.
-- @treturn string|nil The translation, or nil if that entry is
-- not translated yet, or the name is unknown. Empty descriptions
-- will return an empty string. Empty names return the usual "Unknown key:".
-- The result should be used immediately or it may become outdated.
--
-- @function Babelfish.translate_prototype_name
function Remote.translate_prototype_name(pindex, type, name)
  -- The other mod might send the index of an offline player!
  verify(pindex, 'NaturalNumber', 'No player with given index: ', pindex)
  assertify(game.players[pindex], 'No player with given index: ', pindex)
  local dict = Savedata:sget_pdata(nil, pindex).dict
  --
  return dict:translate_name(type, name) end
  
  
-- -------
-- Retrieves the LanguageCode of a player.
-- 
-- @tparam NaturalNumber pindex A @{FOBJ LuaPlayer.index}.
-- @return (@{Babelfish.LanguageCode|LanguageCode} or @{nil}).
--
-- @function Babelfish.get_player_language_code
function Deprecated.get_player_language_code(pindex)
  verify(pindex, 'NaturalNumber', 'Babelfish: Invalid player index.')
  assertify(game.players[pindex], 'No player with given index: ', pindex)
  local dict = Savedata:sget_pdata(nil, pindex).dict
  return (dict and dict.language_code) or nil end
  
  
-- -------
-- Retrieves all translation percentages.
-- This is the same data that the built-in status indicator uses.
-- Includes only languages that have been seen on this map at least once.
-- 
-- This is the total percentage intended for GUI visualization only.
-- Use @{Babelfish.can_find_prototype_names} to get the proper per-SearchType status.
-- 
-- @treturn table A mapping (@{Babelfish.LanguageCode|LanguageCode} → @{NaturalNumber})
-- where the number is between 0 and 100 inclusive.
-- 
-- @function Babelfish.get_translation_percentages
function Deprecated.get_translation_percentages()
  local r = {}
  for code, dict in ntuples(2, Savedata.dicts) do
    r[code] = dict:get_percentage()
    end
  return r end

  
-- -------
-- Triggers an internal update.
--
-- This is meant to be used to circumvent the hard engine limitation of
-- no events being raised in Singleplayer when the locale changes but
-- nothing else changed.
--
-- This can also be triggered by the commands `'/babelfish update'`
-- (singleplayer only) and `'/babelfish reset'` (admin only) respectively.
--
-- @tparam[opt=false] boolean reset Completely resets all translations
-- instead of just performing a normal update.
--
-- @function Babelfish.force_update
function Deprecated.force_update(force)
  -- @future: This can be included in the eventual mini-gui.
  if (force == true) then
    -- Has to fix completely broken Savedata/Dictionary state!
    Table.overwrite(Savedata, Table.dcopy(DefaultSavedata))
    script.get_event_handler('on_configuration_changed')()
  else
    Table.clear(Savedata.players)
    Babelfish.on_player_language_changed()
    end
  end
  
  
--------------------------------------------------------------------------------
-- Commands.  
-- @section
--------------------------------------------------------------------------------

do
  local subcommands
  local on_cmd = script.on_event(defines.events.on_console_command, function(e)
    if (e.command == 'babelfish') then
      local pdata, p = Savedata:sget_pdata(e)
      local f = subcommands[e.parameters]
      if f then
        if f(e, pdata, p) then
          p.print{'babelfish.command-confirm'}
          end
      else
        p.print{'babelfish.unknown-command'}
        end
      end
    end)
  script.on_event(EventManager.events.on_user_panic, function(e)
    local pdata, p = Savedata:sget_pdata(e)
    if subcommands.reset(nil, pdata, p) then
      p.print{e.calming_words, {'babelfish.babelfish'}}
      end
    end)
  --
  subcommands = {
    ----------
    -- `/babelfish update` Updates Singleplayer language when detection failed.
    -- @table update
    update = function(e, pdata, p)
      if game.is_multiplayer() then
        p.print {'babelfish.command-only-in-singleplayer'}
      else
        Deprecated.force_update()
        return true end
      end,
      
    ----------
    -- `/babelfish reset` Deletes all translations and starts from scratch.
    -- Use only when everything else failed.
    -- @table reset
    reset = function(e, pdata, p)
      if game.is_multiplayer() and not p.admin then
        p.print {'babelfish.command-only-by-admin'}
      else
        Deprecated.force_update(true)
        return true end
      end,
      
    ----------
    -- `/babelfish demo` Opens a rudimentary demonstration GUI. Just type
    -- in the upper box to start searching. The gui is not optimized so the
    -- generation of the result icons is a bit slow for large modpacks.
    -- The sidepanel dynamically shows in red/green which SearchTypes
    -- are fully translated.
    --
    -- See also: @{Babelfish.HowToActivateBabelfish|HowToActivateBabelfish}.
    --
    -- @table demo
    demo = function(e, pdata, p)
      if game.is_multiplayer() and not p.admin then
        p.print {'babelfish.command-only-by-admin'}
      else
        local Demo = _ENV.package.loaded["plugins/babelfish-demo/control"]
        if Demo then
          Demo(p):toggle_gui()
        else
          p.print('Demo is not activated.')
          end
        end
      end,
      
    ----------
    -- `/babelfish dump` Prints internal statistics to the attached terminal.
    -- @table dump
    dump = function(e, pdata, p)
      if game.is_multiplayer() and not p.admin then
        p.print {'babelfish.command-only-by-admin'}
      else
        assert(flag.IS_DEV_MODE, 'Dumping is only correct in dev mode!')
        for _, lcode in ipairs{'en', 'de', 'ja'} do
          local dict = Savedata.dicts[lcode]
          if dict then dict:dump_statistics_to_console() end
        
        -- for _, dict in pairs(Savedata.dicts) do
          -- dict:dump_statistics_to_console()
          end
        return true end
      end,
      
    -- -------
    --
    test = function(e, pdata, p)
      if p.name == 'eradicator' then
        --
        for k, v in pairs(pdata.dict) do
          if type(v) == 'table' then
            local holes = 0
            for i=1, v.max do 
              if v[i] == nil then holes = holes + 1 end
              end
            print(('%s had %s holes'):format(k, holes))
            end
          end
        return true end
      end,
      
    }
  end

--------------------------------------------------------------------------------
-- Events.  
-- @section
--------------------------------------------------------------------------------

----------
-- Called when SearchType availability changes.
-- SearchTypes can become available or unavailable.
-- 
-- Mods that want to dynamically adjust their gui or similar must
-- call @{Babelfish.can_translate|can_translate} during this event to
-- get the new state. Other mods can safely ignore this event.
-- 
-- Use @{remotes.events} or @{EventManagerLite.events} to get
-- the event id.
-- 
-- @tfield NaturalNumber player_index
-- @table on_babelfish_translation_state_changed
do end

-- dict   -> raise for all players with that dict
-- pindex -> raise for just one player
  do
  local _raise = function(pindex)
    log:debug('Babelfish: on_babelfish_translation_state_changed: ', pindex)
    return script.raise_event(
      -- Keep it simple! can_translate() already includes all important logic.
      -- Not including extra data encourages mod authors
      -- to use only one function for all updates instead of
      -- writing a special event-data parser.
      EventManager.events.on_babelfish_translation_state_changed,
      {player_index = pindex}
      )
    end
Babelfish.raise_on_translation_state_changed = function(dict, pindex)
  if dict then 
    for pindex, pdata in pairs(Savedata.players) do
      if pdata.dict == dict then _raise(pindex) end
      end
  else
    _raise(assert(pindex))
    end
  end
  end
  
  
  
--------------------------------------------------------------------------------
-- TechnicalDescription.  
-- @section
--------------------------------------------------------------------------------

  
--[[------
A detailed explanation of Babelfish's internal processes.

When a new player joins a game Babelfish asks the player what language they use.
This also happens in any situation in which a player might have changed
their language, or when any base or mod updates have happend. However the
factorio API does not currently offer a way to detect language changes in
Singleplayer.

When Babelfish sees a new language in a game for the first time it makes a copy
of the internal "list of strings that need translation" and sends requests to
_the first connected_ player of that language to translate these strings. To
conserve bandwidth in multiplayer only unique strings are sent. The requests
are initially sent in SearchType priority order, but due to how real networks
work the order in which translations are recieved might differ slightly.

Only one translation process can run at a time - if there are multiple
languages to be translated then they will be translated in sequential order.
There is currently no cross-language priorization of SearchTypes.

When a recieved package is the last package for that language and SearchType
Babelfish will raise the on_babelfish_translation_state_changed event for
each player of that language.

When a change in mod or base game version is detected then Babelfish will
re-start the process of translating all strings. It will also raise
on_babelfish_translation_state_changed for _all_ players regardless of
any actual changes.

Because most mod
updates only change small bits of the locale - if any at all - Babelfish keeps
all old translations. If no _new_ locale keys have been added then
all Babelfish API methods will use the old translations until the new ones
arrive and



@table InternalWorkflow
]]

  
-- -------------------------------------------------------------------------- --
-- Draft                                                                      --
-- -------------------------------------------------------------------------- --
