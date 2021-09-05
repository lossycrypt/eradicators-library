-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Localised string search for mods.
--
-- Babelfish is a caching __translator for prototype localisations__.
-- It automatically detects changes in localisation and updates the translation
-- in the background. In Singleplayer this
-- process happens during the loading screen and is invisible to the player.
-- In Multiplayer translation is done gradually in on_tick to prevent
-- network congestion. Each language is only translated once,
-- so even in Multiplayer the process is instant for most players.
--
-- While translation is running a small status indicator in
-- the upper right corner informs each user of the _approximate_ total progress. 
-- However there is no such progress information on the API, as the 
-- Babelfish uses a SearchTypes priorization system in which i.e. 
-- `"item_name`" may already be completely translated despite the indicator
-- showing a low number like "10%".
--
-- @{Introduction.DevelopmentStatus|Module Status}: Experimental.
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
    -> MIR rejected => impossible
  
  ? Needs engine support.
    Detect game.speed changes outside of on_runtime_mod_setting_changed.
    => Replaced by regular polling for now.
  
  ]]

--[[ Facts:
  
  + In Singleplayer on_string_translated is raised for all 
    requests from exactly one tick before.
  
  + The on_string_translated event's "e.localised_string"
    never contains numbers. They are converted to strings.
    Even if the original request did use numbers.
    
  + When packaging localised strings together the result
    will always be considered "translated". But may contain
    <Unknown key: \"foobar\"> parts.
    
  + Requesting translation of a parametrized lstring *without* *any* 
    parameters will return a result with the parameters
    placeholders intact (i.e. "Foo __1__ bar."). If at least one
    parameter is given all parameters are messed up. This makes
    a lua-side reimplementation theoretically possible. But 
    that's of course way too much work for just reducing traffic a little.
  
  ]]
  
--[[ Related Forum Theads:

  + Interface Request (Unanswered)
    https://forums.factorio.com/viewtopic.php?f=28&t=98695
    "A method to detect changes in player language in Singleplayer."
    
  + Interface Request (Unanswered)
    "LuaPlayer::active_locale" (by raiguard)
    https://forums.factorio.com/99479
    
  + Interface Request (Rejected)
    https://forums.factorio.com/viewtopic.php?f=28&t=98628
    "LuaGameScript.is_headless_server [boolean]"
    
    
  + Interface Request (Unanswered)
    https://forums.factorio.com/viewtopic.php?f=28&t=98698
    "LuaPlayer.unlock_tips_and_tricks_item(name)"
    => May by possible by abusing other trigger types.
    
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

local Verificate  = elreq('erlib/lua/Verificate'   )()
local verify      = Verificate.verify
local isType      = Verificate.isType

local String      = elreq('erlib/lua/String'       )()

local ntuples     = elreq('erlib/lua/Iter/ntuples' )()

local Setting     = elreq('erlib/factorio/Setting' )()
local Locale      = elreq('erlib/factorio/Locale'  )()

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local script = EventManager .get_managed_script    'babelfish'
local import = PluginManager.make_relative_require 'babelfish'
local const  = import '/const'
local null   = '\0'

script.generate_event_name('on_babelfish_translation_state_changed')

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
import '/control/Savedata' -- classify before all other modules!

local Babelfish        = import '/control/Babelfish'
local Dictionary       = import '/control/Dictionary'
                         import '/control/DictionaryFind'
local StatusIndicator  = import '/control/StatusIndicator'
local RawEntries       = import '/control/RawEntries'

local Command          = import '/control/Command'
local Remote           = import '/control/Remote'
remote.add_interface(const.remote.interface_name, Remote)

if flag.IS_DEV_MODE then import '/control/Debug' end

-- -------------------------------------------------------------------------- --
-- Savedata                                                                   --
-- -------------------------------------------------------------------------- --
local Savedata
PluginManager.manage_savedata  ('babelfish', function(_) Savedata = _ end)
  
-- -------------------------------------------------------------------------- --
-- Conditional Events                                                         --
-- -------------------------------------------------------------------------- --

Babelfish.should_update_lcodes = function()
  return (not not Savedata:get_lcode_requesters()) end
  
Babelfish.should_request_translations = function()
  return (not Babelfish.should_update_lcodes())
     and (not not Savedata:get_active_dict())
  end

-- Manages ALL dynamic event de/registration
-- must be ON_LOAD compatible!
Babelfish.update_handlers = function()
  local string_event   = defines.events.on_string_translated
  --
  if Babelfish.should_update_lcodes() then
    log:info('Translation suspended while waiting for language codes.')
    -- At least one player is missing an lcode.
    script.on_event   (string_event, Babelfish.on_string_translated)
    script.on_nth_tick(         300, nil)
    script.on_nth_tick(          60, nil)
    script.on_nth_tick(           1, Babelfish.request_language_codes)
  elseif Babelfish.should_request_translations() then
    log:info('Translation started.')
    -- Send out translation requests.
    script.on_event   (string_event, Babelfish.on_string_translated)
    script.on_nth_tick(         300, Babelfish.on_runtime_mod_setting_changed)
    script.on_nth_tick(          60, StatusIndicator.update_all)
    script.on_nth_tick(           1, Babelfish.request_translations)
  else
    log:info('All translations finished.')
    -- Sleep while nothing is happening.
    script.on_event   (string_event, nil)
    script.on_nth_tick(         300, nil)
    script.on_nth_tick(          60, nil)
    script.on_nth_tick(           1, nil)
    end
  end

-- -------------------------------------------------------------------------- --
-- Load                                                                       --
-- -------------------------------------------------------------------------- --

local function reclassify_all_dictionaries()
  for _, dict in ntuples(2, Savedata.dicts) do  
    Dictionary.reclassify(dict)
    end
  end

local on_load = script.on_load(function(e)
  if not Savedata then return end -- on_load before on_config *again*...
  if Savedata.version ~= const.version.savedata then return end
  --
  reclassify_all_dictionaries()
  Babelfish.update_handlers()
  end)

-- -------------------------------------------------------------------------- --
-- Init / Config                                                              --
-- -------------------------------------------------------------------------- --
  
-- local function did_this_mod_config_change(e)
--   return
--     (not e) or
--     ( (table_size(e.mod_changes) > 0)
--       or e.migration_applied
--       or e.mod_startup_settings_changed )
--   end
  
local function update_all_dictionaries()
  for lcode, dict in ntuples(2, Savedata.dicts) do
    dict:update()
    end
  end
  
-- Force creation of pdata for everyone.
local function init_all_players()
  for pindex in pairs(game.players) do
    Savedata:sget_pdata(nil, pindex)
    end
  end
  
local function set_all_lcodes_dirty()
  for pindex in pairs(Savedata.players) do
    Savedata:set_pdata_lcode_dirty(nil, pindex, true)
    end
  end
  
-- Sometimes an empty event is raised?
-- { migration_applied = false,
--   mod_changes = {},
--   mod_startup_settings_changed = false }
--
script.on_config(function(e)
  --
  -- if Savedata.version ~= const.version.savedata then
    -- log:debug('Savedata version obsolete. Resetting.')
    -- Savedata:reset_to_default()
    -- end
  --
  RawEntries.precompile()
  reclassify_all_dictionaries() -- can't dict:update without
  update_all_dictionaries()
  --
  Savedata:clear_packed_packets()
  Savedata.version = const.version.savedata
  --
  Savedata:clear_volatile_data()
  init_all_players()
  set_all_lcodes_dirty()
  --
  Babelfish.on_runtime_mod_setting_changed()
  on_load()
  end)


-- -------------------------------------------------------------------------- --
-- Other Events                                                               --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- connection status

-- Always watch for potential lcode changes.
script.on_event({
  defines.events. on_player_left_game  ,
  defines.events. on_player_created    ,
  defines.events. on_player_joined_game,
  defines.events. on_player_removed    ,
  },
  Babelfish.on_player_language_changed
  )
  
-- -------------------------------------------------------------------------- --
-- settings
  
script.on_event(defines.events.on_runtime_mod_setting_changed,
  Babelfish.on_runtime_mod_setting_changed)

-- -------------------------------------------------------------------------- --
-- console

script.on_event(defines.events.on_console_command, Command.on_console_command)
script.on_event(EventManager.events.on_user_panic, Command.on_user_panic)
