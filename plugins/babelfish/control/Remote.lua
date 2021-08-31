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
-- local log         = elreq('erlib/lua/Log'          )().Logger  'babelfish'
local stop        = elreq('erlib/lua/Error'        )().Stopper 'babelfish'
local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

local Verificate  = elreq('erlib/lua/Verificate'   )()
local verify      = Verificate.verify
-- local isType      = Verificate.isType

local Table       = elreq('erlib/lua/Table'        )()
-- local Array       = elreq('erlib/lua/Array'        )()
-- local Set         = elreq('erlib/lua/Set'          )()
-- local Filter      = elreq('erlib/lua/Filter'       )()
-- local Vector      = elreq('erlib/lua/Vector'       )()

-- local ntuples     = elreq('erlib/lua/Iter/ntuples' )()
-- local dpairs      = elreq('erlib/lua/Iter/dpairs'  )()
-- local sriapi      = elreq('erlib/lua/Iter/sriapi'  )()

local Setting     = elreq('erlib/factorio/Setting'   )()
-- local Player      = elreq('erlib/factorio/Player'    )()
-- local getp        = Player.get_event_player

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
-- local script = EventManager .get_managed_script    'babelfish'
local import = PluginManager.make_relative_require 'babelfish'
local const  = import '/const'

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Remote = {}

-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --

local SearchTypes      = import '/control/SearchTypes'

-- -------------------------------------------------------------------------- --
-- Savedata                                                                   --
-- -------------------------------------------------------------------------- --
local Savedata
PluginManager.manage_savedata  ('babelfish', function(_) Savedata = _ end)

-- -------------------------------------------------------------------------- --
-- Events                                                                     --
-- -------------------------------------------------------------------------- --


  
--------------------------------------------------------------------------------
-- Remote Interface.  
-- @section
--------------------------------------------------------------------------------

----------
-- The remote interface is named `"babelfish`".
-- @table RemoteInterfaceName
do end


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
-- that name will _additionally_ be included in the search result.  
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
  

  
return Remote