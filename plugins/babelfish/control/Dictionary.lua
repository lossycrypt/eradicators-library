-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------------------------------------
-- Babelfish.
-- @module Babelfish

--[[ Future Possibilities:
 
  + Filter out useless entity prototypes. (explosions, projectiles, etc)
  
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
local log         = elreq('erlib/lua/Log'       )().Logger  'babelfish'
local stop        = elreq('erlib/lua/Error'     )().Stopper 'babelfish'
local assertify   = elreq('erlib/lua/Error'     )().Asserter(stop)

local Class       = elreq('erlib/lua/Class'     )()

local Table       = elreq('erlib/lua/Table'     )()
local Array       = elreq('erlib/lua/Array'     )()

local sriapi      = elreq('erlib/lua/Iter/sriapi' )()
-- local ntuples     = elreq('erlib/lua/Iter/ntuples')()
local array_pairs = elreq('erlib/lua/Iter/array_pairs')()

local Locale      = elreq('erlib/factorio/Locale' )()
      
local string_gsub
    = string.gsub
      
local pairs, assert
    = pairs, assert

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local import = PluginManager.make_relative_require'babelfish'
local const  = import '/const'

local eindex = const.index.entry
local rindex = const.index.request

local RawEntries       = import '/control/RawEntries'
local Babelfish        = import '/control/Babelfish'

local SearchTypes      = import '/control/SearchTypes'
local Local            = import '/locallib'
                      
local nlstring_is_equal = Locale.nlstring_is_equal

-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- Savedata                                                                   --
-- -------------------------------------------------------------------------- --
local Savedata
PluginManager.manage_savedata  ('babelfish', function(_) Savedata = _ end)

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Dictionary = Class.SimpleClass(
  -- initializer
  function()
    local dict = {
      -- ['requests'  ] = {}, -- DenseArray
      -- ['SearchType'] = {}, -- DenseArray for each type
      }  
    return dict end,
  -- finalizer
  function(dict)
    dict:update()
    end
  )
  
-- -------------------------------------------------------------------------- --
-- Status                                                                     --
-- -------------------------------------------------------------------------- --

-- If the dictionary has anything left to request.
function Dictionary.has_requests(dict)
  return (dict.request_uids.n > 0) end
  
-- How much is translated yet. For informing the player.
function Dictionary.get_percentage(dict)
  return math.floor(
    100 * (dict.request_uids.max - dict.request_uids.n)
    / dict.request_uids.max )
  end

-- All keys have a translation, but some of the translations
-- may be outdated due to on_config_changed.
function Dictionary.is_type_fully_populated(dict, type)
  if dict[type] == nil then
    -- 2021-07-21: I am unsure if this can happen naturally or
    -- if this only happens when changing const.type_data in
    -- the dev environment where on_config_changed isn't triggered properly.
    dict:update()
    game.auto_save('babelfish-bugreport')
    game.print(
      '[color=red]WARNING![/color]\n'
      ..'[color=acid]'
      ..'Babelfish has missed a change in requested search_types.\n'
      ..'Please submit a detailed report which mods you just\n'
      ..'installed and uninstalled, and/or which mod settings you changed.\n'
      ..'Your game has been fixed and saved as [color=red]_autosave-babelfish-bugreport[/color].\n'
      ..'You should use the [color=red]/babelfish reset[/color] command now and save again.'
      ..'[/color]'
      )
    end
  --
  assert(dict[type])
  return (dict[type].n == dict[type].max)
  end

-- -------------------------------------------------------------------------- --
-- Update                                                                     --
-- -------------------------------------------------------------------------- --
  
-- Clear up old data and request full re-translation.
function Dictionary.update(dict)
  local profile = Local.get_profiler()
  --
  log:debug('Dictionary.update: ', Savedata:get_dict_lcode(dict) or '(new)')
  dict:repair()
  dict:set_request_uids(Array.reverse(Table.keys(RawEntries.requests)))
  --
  profile('Dictionary.update took: ')
  end

  
-- Sets packet uids sheduled for translation.
--
-- @tparam DenseArrayOfNaturalNumber request_uids
--
function Dictionary.set_request_uids(dict, request_uids)
  dict.request_uids     = Table.values(request_uids)
  dict.request_uids.max = #request_uids -- all-time maxium
  dict.request_uids.n   = #request_uids -- current maximum
  dict.request_uids.i   = #request_uids -- next uid to be requested (can be negative)
  end
  
  
-- Measures the length of the DenseArray part.
-- The SparseArray part I-n to I-max is ignored.
--
-- @treturn boolean if n changed at all.
--
function Dictionary.update_n(dict, type)
  local this = assert(dict[type])
  local old_n = this.n
  --
  this.n = this.n or 0
  while this[this.n + 1] do this.n = this.n + 1 end -- implicit (i >= this.max)
  --
  local did_n_change = (this.n ~= old_n   )
  local is_n_max     = (this.n == this.max)
  local did_n_change_to_max = (did_n_change and is_n_max)
  --
  if did_n_change_to_max then
    log:debug(('Fully populated %s of %s'):format(type, Savedata:get_dict_lcode(dict)))
    -- There are too many edge cases around half-translated dictionaries
    -- and/or change in requested search types to reasonably detect 
    -- if there was a change or not. So this must always be raised.
    Babelfish.raise_on_translation_state_changed(dict)
    end
  end

  
-- Clear all invalid data.
function Dictionary.repair(dict)
  --
  -- Wipe ALL old data.
  Table.clear(dict, SearchTypes.get_requested_array_ref())
  local old_translations = Table.scopy(dict) -- only requested types remaining
  Table.clear(dict)
  --
  -- Create empty tables.
  dict:set_request_uids{}
  for _, type in SearchTypes.requested_ipairs() do
    dict[type] = {n = 0, max = RawEntries.max_indexes[type]}
    end
  --
  -- Most mod updates only have minor or no locale changes.
  -- Keep old translations until new ones arrive for a smoother transition.
  for type, old_entries in pairs(old_translations) do
    for index, old_entry in array_pairs(old_entries, 1, old_entries.max) do
      local raw_entry = RawEntries.by_name[type][old_entry[eindex.name]]
      local word      = old_entry[eindex.word]
      if raw_entry and word then dict:set_entry_translation(raw_entry, word) end
      end
    dict:update_n(type)
    end
  end


-- -------------------------------------------------------------------------- --
-- Translation                                                                --
-- -------------------------------------------------------------------------- --
  
do

  local _is_exact_unknown_key_string = function(type, name, word)
    return word == (
      'Unknown key: "'..string_gsub(type, '_', '-')..'.'..name..'"'
      )
    end

  -- Set a single translation for a single entry.
  function Dictionary.set_entry_translation(dict, raw_entry, word)
    local type = raw_entry[eindex.type]
    local name = raw_entry[eindex.name]
    --
    -- When using packed requests unknown descriptions are translated as
    -- "unknown key" but unlike unknown item names vanilla shows them
    -- as empty. Not storing them saves space and fixes search results.
    if Babelfish.is_packaging_enabled()
    and SearchTypes.is_description(type)
    and _is_exact_unknown_key_string(type, name, word)
    then
      -- Hackfix: Preserve real length for dump_statistics()
      word = (not flag.IS_DEV_MODE) and '' or (''):rep(#word)
      end
    --
    -- Always create a fresh entry table to avoid table-recycling bugs.
    dict[type][raw_entry[eindex.index]] = {
      [eindex.word] = word or '',
      [eindex.name] = name,
      }
    --
    dict:update_n(type)
    end
    
  end

    
-- -------------------------------------------------------------------------- --
  
-- Must be called EVERY TICK when translating for correct delay handling.
-- 
-- Let's `i` run negative after all packets have been requested
-- to prevent re-requesting the final n packages multiple times.
do
  local requests = RawEntries.requests
  function Dictionary.iter_requests(dict)
    local uids  = dict.request_uids
    local delay = -1 * const.network.rerequest_delay * Local.ticks_per_second_int()
    return function()
      local uid = uids[uids.i] -- uid becomes nil when i falls below 0
      uids.i = uids.i - 1
      if uids.i < delay then uids.i = uids.n end
      return requests[uid] end
    end
  end

-- -------------------------------------------------------------------------- --
  
do
    
  -- Remove uid by index. Fix i and n.
  local _remove_uid = function(uids, index)
    assert(uids.n == #uids)
    Array.shuffle_pop(uids, index);
    uids.n = #uids
    uids.i = math.min(uids.i, uids.n)
    end
    
  -- Remove the uid that contains lstring and return the request.
  -- @treturn RawRequest
  -- @treturn number Iterations used to find the lstring uid.
  local _iter = function(dict, lstring)
    local uids = dict.request_uids
    for uid, index in sriapi(uids) do
      local raw_request = RawEntries.requests[uid]
      if nlstring_is_equal(raw_request[rindex.lstring], lstring) then
        --
        if flag.IS_DEV_MODE then
          local count = uids.n - index + 1
          if count > 1 then log:debugf('Lstring->request took %s trials.', count) end
          end
        --
        _remove_uid(uids, index)
        return sriapi(raw_request[rindex.entries])
        end
      end
    log:debug('Recieved unrequested lstring. Ignoring')
    return ercfg.SKIP end

  -- Set all translations from a single requests entries.
  -- Implicitly ignores
  --
  function Dictionary.set_lstring_translation(dict, lstring, word)
    for entry in _iter(dict, lstring) do
      dict:set_entry_translation(entry, word)
      end
    end
    
  end
  
  
return Dictionary