-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------------------------------------
-- Babelfish.
-- @module Babelfish

--[[ Notes:

  All "array" tables *must* be sorted by translation priority!

  priority_index : The exact priority number.
  ordered_index  : Any number, ordered in priority order.
  
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

local Verificate  = elreq('erlib/lua/Verificate'   )()
local verify      = Verificate.verify

local Table       = elreq('erlib/lua/Table'        )()
local Array       = elreq('erlib/lua/Array'        )()
local Set         = elreq('erlib/lua/Set'          )()
local Filter      = elreq('erlib/lua/Filter'       )()

local Cache       = elreq('erlib/factorio/Cache'   )()

local ipairs
    = ipairs

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local import = PluginManager.make_relative_require 'babelfish'
local const  = import '/const'

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local SearchTypes = {}

-- -------------------------------------------------------------------------- --
-- All Stages                                                                 --
-- -------------------------------------------------------------------------- --

-- {priority_index -> search_type}
local supported_array = Table.map(const.type_data, function(v) return v.type end, {})

-- {search_type -> priority_index}
local supported_set   = Table.flip(supported_array)

-- Sorts an array of search_type by translation priority
function SearchTypes.sort(array)
  table.sort(array, function(a, b) return supported_set[a] < supported_set[b] end)
  return array end

-- Determines if a type is supported at all.
function SearchTypes.is_supported(type)
  return not not supported_set[type] end

function SearchTypes.get_supported_array()
  return Array.scopy(supported_array) end

function SearchTypes.get_supported_set()
  return Set.from_values(supported_array) end
  
-- -------------------------------------------------------------------------- --
-- on_load (remote calls)                                                     --
-- -------------------------------------------------------------------------- --

-- Failed experiment. Requires using mod to call in
-- all three events: init/config/load.

-- local requested_array = {}
-- local requested_set   = {}
-- 
-- function SearchTypes.add_type(type, entries)
--   verify(entries, true, 'Given table was not a <set>.') -- Custom entries are not supported yet.
--   assertify(SearchTypes.is_supported(type), 'Not a known SearchType: ', type)
--   --
--   table.insert(requested_array, type)
--   SearchTypes.sort(requested_array)
--   requested_set[type] = true
--   end
  
-- -------------------------------------------------------------------------- --
-- Control Stage                                                              --
-- -------------------------------------------------------------------------- --

-- pre-sorted in settings-final-fixes
local function get_requested_values()
  return Array.scopy(game.mod_setting_prototypes
  [const.setting_name.search_types].allowed_values)
  end

-- {ordered_index -> search_type}
local requested_array = Cache.AutoCache(function(r)
  Table.overwrite(r, get_requested_values())
  end)
  
-- {search_type -> true}
local requested_set = Cache.AutoCache(function(r)
  Table.overwrite(r, Set.from_values(get_requested_values()))
  end)
  
-- {ordered_index -> search_type}
-- local not_requested_array = Cache.AutoCache(function(r)
--   -- Don't attach Set meta to internal tables.
--   -- (scopy also triggers AutoCache)
--   local supported_set = Set(Table.scopy(supported_set)) 
--   local requested_set = Set(Table.scopy(requested_set))
--   Table.overwrite(r, Table.keys(supported_set - requested_set))
--   SearchTypes.sort(r) -- not currently required
--   end)
  
--
function SearchTypes.assert(type)
  assertify(not not supported_set[type], 'SearchType unknown: '      , type)
  assertify(not not requested_set[type], 'SearchType not activated: ', type)
  return true end

--
SearchTypes.is_description = Filter.string_postfix('_description')
  
  
--
function SearchTypes.requested_ipairs()
  return ipairs(requested_array)
  end
  
--
-- function SearchTypes.get_not_requested_array()
--   return Array.scopy(not_requested_array)
--   end

--
function SearchTypes.get_requested_array_ref()
  -- return Array.scopy(requested_array)
  return requested_array
  end
  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
return SearchTypes
