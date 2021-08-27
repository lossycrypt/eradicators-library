-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
-- -------------------------------------------------------------------------- --

--[[ Notes:

  Code-minimialistic preparation of requests. KISS.

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
-- local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

-- local Verificate  = elreq('erlib/lua/Verificate'   )()
-- local verify      = Verificate.verify
-- local isType      = Verificate.isType

local Table       = elreq('erlib/lua/Table'        )()
local Array       = elreq('erlib/lua/Array'        )()
-- local Set         = elreq('erlib/lua/Set'          )()
-- local Filter      = elreq('erlib/lua/Filter'       )()
-- local Vector      = elreq('erlib/lua/Vector'       )()
local Cache       = elreq('erlib/factorio/Cache'  )()
-- local Memoize     = elreq('erlib/lua/Meta/Memoize')()
local L           = elreq('erlib/lua/Lambda'    )()

-- local ntuples     = elreq('erlib/lua/Iter/ntuples' )()
-- local dpairs      = elreq('erlib/lua/Iter/dpairs'  )()
-- local sriapi      = elreq('erlib/lua/Iter/sriapi'  )()

local Locale      = elreq('erlib/factorio/Locale' )()
-- local Setting     = elreq('erlib/factorio/Setting'   )()
-- local Player      = elreq('erlib/factorio/Player'    )()
-- local getp        = Player.get_event_player

local Prototype   = elreq('erlib/factorio/Prototype')()


local ipairs, pairs
    = ipairs, pairs

local table_insert
    = table.insert

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local import = PluginManager.make_relative_require'babelfish'
local const  = import '/const'

local eindex = const.index.entry
local rindex = const.index.request

local SearchTypes      = import '/control/SearchTypes'
local Local            = import '/locallib'

-- local Lstring          = import '/control/Lstring'
-- local lstring_is_equal = Lstring.is_equal
-- local lstring_ident    = Lstring.ident
-- local nlstring_is_equal = Locale.nlstring_is_equal
local nlstring_ident    = Locale.nlstring_to_string
local lstring_norm      = Locale.normalise

local TypeBytes = Table.map(const.type_data, L['x -> x.longest, x.type'], {})

-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --

-- "type"  : "item_name", "virtual_signal_description" (TranslationType)
-- "class" : "item", "virtual_signal"
-- "lkey"  : "name" or "description"
local function type2class(str)
  for _, lkey in ipairs{'name', 'description'} do
    local class, count = str:gsub('_'..lkey..'$', '')
    if count > 0 then return class, lkey end
    end
  return stop('Invalid type string: ', str) end

  
-- detect localisable types
-- local types = (function(r)
--   for k in game.help():gmatch('(.-)[%[%]RW ]*\n') do
--     if k:find'_prototypes$' and not k:find'^get_' then
--       local f = function(key) return select(2, pairs(game[k])(nil))[key] end
--       if pcall(f, 'localised_name') and pcall(f, 'localised_description') then
--         table.insert(r, k:match'(.-)_prototypes')
--         end
--       end
--     end
--   return r end){}
  
  
-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local RawEntries = {}

-- -------------------------------------------------------------------------- --
-- INIT

local function trigger_auto_cache(key)
  return assert(nil == RawEntries[key][{}]) end

-- Triggers all AutoCaches once to prevent lag-spikes later.
-- MUST NEVER CHANGE THE GAME STATE!
function RawEntries.precompile()
  local profile = Local.get_profiler()
  --
  RawEntries.precompile = ercfg.SKIP
  --
  -- Order is important for correct profiling.
  for _, key in ipairs{'ordered', 'requests', 'by_name', 'max_indexes'} do
    trigger_auto_cache(key)
    end
  --
  profile('Populating RawEntries.precompile total: ')
  end

-- -------------------------------------------------------------------------- --
-- LOOKUP
--
-- Array {translation_type -> {entry_name -> {entry} }
RawEntries.by_name = Cache.AutoCache(function(r)
  local profile = Local.get_profiler()
  --
  for type, entries in pairs(RawEntries.ordered) do
    r[type] = Table.map(
      entries,
      function(entry) return entry, entry[eindex.name] end,
      {})
    end
  --
  profile('Populating RawEntries.by_name     took: ')
  end)

  
-- -------------------------------------------------------------------------- --
-- Array {translation_type -> maximum_index}
RawEntries.max_indexes = Cache.AutoCache(function(r)
  local profile = Local.get_profiler()
  --
  for _, type in SearchTypes.requested_ipairs() do
    r[type] = #game[(type2class(type))..'_prototypes']
    end
  --
  profile('Populating RawEntries.max_indexes took: ')
  end)


-- -------------------------------------------------------------------------- --
-- AUTHORATIVE entry order per type. Determines find() result order.
-- Array of untranslated entries, sorted by natural prototype order.#
--
-- Array {translation_type -> { entry_index -> entry } }
RawEntries.ordered = Cache.AutoCache(function(r)
  local profile = Local.get_profiler()
  --
  for _, type in SearchTypes.requested_ipairs() do
    local class, lkey = type2class(type)
    r[type] = Array(Table.values(game[class..'_prototypes']))
      :sort(function(a, b)
        return Prototype.get_absolute_order(class, a.name)
             < Prototype.get_absolute_order(class, b.name)
        end)
      :map(function(prototype, index) return {
        [eindex.type   ] = type,
        [eindex.name   ] = prototype.name,
        [eindex.lstring] = lstring_norm(prototype['localised_' .. lkey]),
        [eindex.index  ] = index,
        } end)
    end
  --
  profile('Populating RawEntries.ordered     took: ')
  end)

    
-- -------------------------------------------------------------------------- --
-- AUTHORATIVE translation request order. Array that maps each
-- UNIQUE lstring to an array of untranslated entries.
--
-- Array {request_uid -> {request ~> {entry, entry, ...} } }

-- Index [1] : Highest priority
-- Index [n] : Lowest  priority

RawEntries.requests = Cache.AutoCache(function(r)
  local profile = Local.get_profiler()
  --
  local lookup = {}
  for _, type in SearchTypes.requested_ipairs() do
    for _, entry in ipairs(RawEntries.ordered[type]) do
      local ident   = nlstring_ident(entry[eindex.lstring])
      local request = lookup[ident] or (function(request)
        local uid = #r+1
        r[uid], lookup[ident]   = request, request
        request[rindex.lstring] = entry[eindex.lstring]
        request[rindex.entries] = {}
        request[rindex.bytes  ] = #ident + TypeBytes[type]
        request[rindex.uid    ] = uid
        return request end){}
      --
      table_insert(request[rindex.entries], entry)
      end
    end
  --
  profile('Populating RawEntries.requests    took: ')
  end)
  
  
  
  
-- -------------------------------------------------------------------------- --
return RawEntries