-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------------------------------------
-- Babelfish.
-- @module Babelfish

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
-- local log         = elreq('erlib/lua/Log'          )().Logger  'babelfish'
local stop        = elreq('erlib/lua/Error'        )().Stopper 'babelfish'
local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

local Verificate  = elreq('erlib/lua/Verificate'   )()
local verify      = Verificate.verify

local Table       = elreq('erlib/lua/Table'        )()

local Setting     = elreq('erlib/factorio/Setting'   )()

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
-- local script = EventManager .get_managed_script    'babelfish'
local import = PluginManager.make_relative_require 'babelfish'
local const  = import '/const'

local SearchTypes      = import '/control/SearchTypes'

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Remote = {}

-- -------------------------------------------------------------------------- --
-- Savedata                                                                   --
-- -------------------------------------------------------------------------- --
local Savedata
PluginManager.manage_savedata  ('babelfish', function(_) Savedata = _ end)

--------------------------------------------------------------------------------
-- Remote Interface.  
-- @section
--------------------------------------------------------------------------------

----------
-- The remote interface is named `"babelfish`".
-- @table RemoteInterfaceName
do end



-- @2021-09-01: Failed runtime search type activativation experiment

-- -------
-- Activates search types.  
-- __This function must be called from an on\_load event handler.__ 
--
-- @tparam set types A mapping of @{Babelfish.SearchType|SearchType} strings to true.
--
-- @usage
--   script.on_load(function()
--     remote.call('babelfish', 'add_search_type', {
--       item_name   = true,
--       recipe_name = true,
--       })
--     end)
--
-- @function Babelfish.add_search_types
-- function Remote.add_search_types(types)
--   if nil ~= rawget(_ENV, 'game') then
--     stop('Babelfish.add_search_type must be called from on_load.')
--     end
--   -- Factorio pairs() preserves key order.
--   for type, entries in pairs(types) do
--     -- future syntax with custom translations:
--     -- {recipe_name = {name = lstring, name = lstring}}
--     SearchTypes.add_type(type, entries)
--     end
--   end
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
function Remote.can_translate(pindex, types)
  return (Remote.find_prototype_names(pindex, types, '', {limit = 0})) end


----------
-- Given a user input, finds prototype names.
--
-- __Search Behavior:__
--
-- All searches are conducted in __lower-case__ (as far as @{string.lower}
-- works in that language). In the SearchType order given,
-- and in prototype `order` specific order.
--
-- As in vanilla, searching is done only on names, not descriptions. And 
-- unlocalised names will be found as "Unknown Key:". But there are some
-- sublte intentional differences to vanilla behavior:
--
-- 1. If `word` is an exact prototype name (i.e. "iron-plate") 
-- that name will _additionally_ be included in the search result.  
-- 2. Babelfish does not filter prototypes. The search result includes names
-- of all matching prototypes including hidden items, void recipes, explosion entities
-- and other garbage.
-- 3. Babelfish understands some unicode whitespace (vanilla does _not_).
-- 
-- __Mod Settings:__
-- 
-- Some aspects of the search, such as "fuzzy" mode are controlled directly
-- by each user via mod-settings so you don't have to worry about those.
-- 
-- __Performance Tips:__
-- 
-- 1. Babelfish searches are highly optimized, but in large modpacks they can
-- still take a few milliseconds. When called directly from an `on_gui_text_changed`
-- event handler this can cause noticible lag-spikes due to the high frequency
-- with which that even occurs while a player is typing. A better solution is
-- to impose a delay after the last keypress or to use an `on_tick` based
-- polling solution. It is recommended to search only once per second.
-- 
-- 2. Babelfish does not impose a minimum word length. The @{EmptyString} will
-- match everything. It is recommended to impose a minimum length of
-- two characters on `word`, or use the `limit` option to reduce the size
-- of the returned table.
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
--   if ok then
--     print(serpent.block(results))
--     end
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
-- @tparam string word The user input.
-- @param options (@{table})
-- @tparam[opt=inf] Integer options.limit Search will return at most this
-- many names. This may result in some of the returned sub-tables being empty.
-- 
-- @treturn boolean|nil The status code.  
--
--   @{nil} means: The language for that player has not been detected yet.
--   This will hardly ever happen in reality. Just try again a second later.
--   __The search result is also nil.__
--
--   @{false} means: Babelfish is still translating some or all of the requested
--   SearchTypes. An incomplete best-effort search result is returned.
--   You can use that partial result or try again later. If you chose to
--   inform the player you can use the @{FAPI Concepts LocalisedString}
--   `{'babelfish.translation-in-progress'}` or a custom message.
--
--   @{true} means: No problems occured.  
--
-- @treturn table|nil The search result. A table mapping each requested
-- SearchType to a @{Types.set|set} of prototype names. 
--
-- @function Babelfish.find_prototype_names
function Remote.find_prototype_names(pindex, types, word, options)
  verify(pindex, 'NaturalNumber', 'No player with given index: ', pindex)
  assertify(game.players[pindex], 'No player with given index: ', pindex)
  verify(options, 'tbl|nil', 'Invalid options.') --future: remove redundant verify
  local dict = Savedata:sget_pdata(nil, pindex).dict
  if not dict then return nil, nil end -- while waiting for language_code
  --
  options = options or {}
  options.mode = Setting.get_value(pindex, const.setting_name.string_match_type)
  --
  return dict:find(Table.plural(types), word, options) end


----------
-- Retrieves the localised name or description of a single prototype.
--
-- @tparam NaturalNumber pindex A @{FOBJ LuaPlayer.index}.
-- @tparam string type A @{Babelfish.SearchType|SearchType}.
-- @tparam string name A prototype name.
-- @treturn string|nil The translation, or nil if that entry is
-- not translated yet. Unlocalised descriptions
-- will return an empty string. Unlocalised names return the usual "Unknown key:".
-- __The result should be used immediately__ or it may become outdated.
--
-- @function Babelfish.translate_prototype_name
function Remote.translate_prototype_name(pindex, type, name)
  -- The other mod might send the index of an offline player!
  verify(pindex, 'NaturalNumber', 'No player with given index: ', pindex)
  assertify(game.players[pindex], 'No player with given index: ', pindex)
  local dict = Savedata:sget_pdata(nil, pindex).dict
  --
  return dict:translate_name(type, name) end
  

  
return Remote