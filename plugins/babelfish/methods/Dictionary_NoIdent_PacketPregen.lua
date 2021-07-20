-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
-- -------------------------------------------------------------------------- --

--[[ Keep it simple:

  Babelfish does the heavy lifting regarding translation. But the
  search function should only supply a minimal interface to build mods on.
  
  ]]

--[[ Won't implement:
  
  Mods can combine search results as they see fit. Babelfish wont
  do specific combinations like "search recipe and ingredients and products".
  
  Babelfish only filters names, not prototype properties.
  Hidden/Void/etc items/recipes must be filtered by the mod.
  
  ]]

--[[ Future Possibilities:

  + Cache find resulsts instead of "lower" strings
    to reduce global data at cost of local data?
    1000 copies of vanilla search result for "i" take about 100MB (~2500 entries).
    retrieving cache is about ~30 times faster IF the result
    does not need to be deep-copied. Dcopy() makes it SLOWER than without cache.
    Cache must be very careful about desyncs so it's only allow
    on fully translated dictionaries. Cache must be keyed to:
    language, match mode, word. If any options are present ignore cache.
  
  + Filter out useless entity prototypes. (explosions, projectiles, etc)
  
  + Custom utf8:lower() string functions.
    Nichtmal ('Ä'):lower() funktioniert! Also müssen quasi alle
    nicht-englischen sprachen auf Unicode umgestellt werden.
    => Für Performance kann man Englisch als einziges lua-nativ lassen?
       Aber nur bei der Suche. Beim Speichern kann mans alles richtig machen.
  
  ]]
  
--[[ Facts:

  + Localised strings from prototypes never contain numbers or nils.
    They are pre-converted to strings.

  + The on_string_translated event's "e.localised_string" also
    never contains numbers. They are converted to strings.
    Even if the original request did use numbers.
    
  + When packaging localised strings together the result
    will always be considered "translated". But may contain
    <Unknown key: \"foobar\"> parts.
    
  + Requesting translation of a parametrized lstring *without* *any* 
    parameters will return a result with the parameters
    placeholders intact (i.e. "Foo __1__ bar."). If at least one
    parameter is given all parameters are messed up. This makes
    a lua-side reimplementation theoretically possible.
    
  ]]
  
--[[ Related Forum Theads:

  + Bug Report ("Won't Fix")
    https://forums.factorio.com/viewtopic.php?f=58&t=98676
    Localised string literal {""} without parameters is converted to
    "" the empty string in on_string_translated.
    => If this ever becomes a problem adjust equ_lstring
    
  + Bug Report ("Won't Fix")
    https://forums.factorio.com/viewtopic.php?f=58&t=98704
    Unicode search is case-sensitive in Russian
    => Consider finding a unicode-capable lua library.
    => As the main usecase is string.lower() it would be sufficent
       to grab a bunch of mapping tables and implement it myself.
    
  + Interface Request ("Unlikely")
    https://forums.factorio.com/viewtopic.php?f=28&t=98680
    Read access to interface setting "Fuzzy search"

  + Interface Request (Unanswered)
    https://forums.factorio.com/viewtopic.php?f=28&t=98695
    A method to detect changes in player language in Singleplayer.
    
  + Interface Request (Unanswered)
    https://forums.factorio.com/viewtopic.php?f=28&t=98628
    LuaGameScript.is_headless_server [boolean]	
    
  + Interface Request (Unanswered)
    https://forums.factorio.com/viewtopic.php?f=28&t=98698
    LuaPlayer.unlock_tips_and_tricks_item(name)
    
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
local log         = elreq('erlib/lua/Log'       )().Logger  'BabelfishDictionary'
local stop        = elreq('erlib/lua/Error'     )().Stopper 'BabelfishDictionary'

local Verificate  = elreq('erlib/lua/Verificate')()
local verify      = Verificate.verify
local assertify   = elreq('erlib/lua/Error'     )().Asserter(stop)
                                                
local Class       = elreq('erlib/lua/Class'     )()
local Filter      = elreq('erlib/lua/Filter'    )()
local String      = elreq('erlib/lua/String'    )()
-- local remove_rich_text_tags = String.remove_rich_text_tags

local Table       = elreq('erlib/lua/Table'     )()
local Array       = elreq('erlib/lua/Array'     )()
local Set         = elreq('erlib/lua/Set'       )()
local Memoize     = elreq('erlib/lua/Meta/Memoize')()

local sriapi      = elreq('erlib/lua/Iter/sriapi' )()
local dpairs      = elreq('erlib/lua/Iter/dpairs' )()
local ntuples     = elreq('erlib/lua/Iter/ntuples')()

local Cache       = elreq('erlib/factorio/Cache'  )()
local Locale      = elreq('erlib/factorio/Locale' )()
local Setting     = elreq('erlib/factorio/Setting')()
local Prototype   = elreq('erlib/factorio/Prototype')()

local pairs, pcall, string_find, type, string_gmatch, string_lower, string_gsub
    = pairs, pcall, string.find, type, string.gmatch, string.lower, string.gsub

-- -------------------------------------------------------------------------- --
-- UTF8 (Dummy Implementation)                                                --
-- -------------------------------------------------------------------------- --
-- for future compatibility

local Utf8 = {
  lower = string.lower,
  find  = string.find ,
  to_array              = String.to_array,
  find_fuzzy            = String.find_fuzzy,
  remove_whitespace     = String.remove_whitespace,
  remove_rich_text_tags = String.remove_rich_text_tags,
  }
        
local utf8_find = Utf8.find
        
-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local import = PluginManager.make_relative_require'babelfish'
local const  = import '/const'
local null   = '\0'

local SupportedTypes = 
  Table.map(const.type_data, function(v) return true, v.type end, {})
  
local TypeBytes = 
  Table.map(const.type_data, function(v) return v.longest, v.type end, {})
  
local function get_requested_search_types() -- DenseArray
  return game.mod_setting_prototypes[const.setting_name.search_types].allowed_values
  end
  
local function get_not_requested_search_types()
  return Set.from_keys(SupportedTypes)
    :complement(Set.from_values(get_requested_search_types()))
  end
  
local RequestedTypes = Cache.AutoCache(function(r) -- PseudoSet
  for k, v in ipairs(get_requested_search_types()) do r[v] = true end
  end)

-- -------------------------------------------------------------------------- --
-- Indexes                                                                    --
-- -------------------------------------------------------------------------- --
local eindex = { -- Entry data index
  name  = 2,
  -- translated entries only
  -- lower = 1,
  word  = 1,
  -- requested entries only
  index = 3,
  type  = 4,
  -- transitional entries only (re-translation after on_config)
  -- temp  = 5, -- boolean
  }
  
local rindex = { -- Request data index
  lstring = 1,
  entries = 2,
  bytes   = 3,
  -- packed request only
  uid     = 4,
  }
  
-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Dictionary = Class.SimpleClass(
  -- initializer
  function(language_code)
    local self = {
      language_code        = language_code,
      native_language_name = assert(
        const.native_language_name[language_code], 'Invalid language_code'),
      }  
    return self end,
  -- finalizer
  function(self)
    self:update()
    end
  )
  
-- -------------------------------------------------------------------------- --
-- Specialized Library                                                            --
-- -------------------------------------------------------------------------- --
-- These functions are based on the observation that the engine
-- "normalizes" localised strings in prototypes. So these
-- functions ONLY WORK if the lstring does NOT CONTAIN numbers or nils.
  
-- 3 times faster than Table.is_equal
local equ_lstring; do
  local is_str = {string = true, table = false}
  function equ_lstring(A, B)
    if A == B then return true end
    if is_str[type(A)] or is_str[type(B)] then return false end
    local n = #A; if n ~= #B then return false end
    for i=1, n do if not equ_lstring(A[i], B[i]) then return false end end
    return true end
  end

-- Inverse-order search for requests.
-- local mt_lstring_indexed_array = {
--   __index = function(self, lstring)
--     for i=#self, 1, -1  do
--       local v = self[i] -- might require rawget or setmetatable(self, nil)
--       if equ_lstring(v[1], lstring) then return v end
--       end
--     end,
--   }

-- Specialized serializer.
-- Result is identical to serpent.line(lstring, nil).
-- 4 times faster than serpent.line
local function lstring_ident(lstring)
  local function f(lstring, arr)
    if type(lstring) == 'string' then
      arr[#arr+1] = '\"'
      arr[#arr+1] = lstring
      arr[#arr+1] = '\"'
    else
      arr[#arr+1] = '{'
      for i=1, #lstring-1 do 
        f(lstring[i], arr)
        arr[#arr+1] = ', '
        end
      f(lstring[#lstring], arr)
      arr[#arr+1] = '}'
      end
    return arr end
  return table.concat(f(lstring, {})) end
  
  
-- Takes a generically joined localised string {'',{'__bla__'},'5'}
-- and compresses it to fit the engine limit of 20 parameters + 1 key.
-- local function lstring_compact(lstring)
--   -- Example:
--   -- 5 == #{'',1,2,3,4} 
--   -- 3 == #{'',{'',1,2},{'',3,4}}
--   -- 2 == #{'',{'',{'',1,2},{'',3,4}}}
--   --
--   assertify(lstring[1] == '', 'Uncompressible lstring: ', lstring)
--   local function f ()
--     local k = 1
--     for i=2, #lstring, 20 do
--       k = k + 1
--       local t = {''}
--       for j=0, 19 do
--         t[j+2] = lstring[i+j]
--         lstring[i+j] = nil
--         end
--       lstring[k] = t
--       end
--     end
--   while #lstring > 21 do f() end
--   return lstring end

  
  
-- Pre-calculating the full order string makes sorting 12 times faster.

-- V1
--
-- local get_full_prototype_order; do
--   local has_group = setmetatable({},{__index=function(self, object_name)
--     local category = object_name:match('Lua(.+)Prototype')
--       :gsub('%u','_%1'):sub(2):lower() -- "VirutalSignal" -> "virtual_signal"
--     for _, prot in pairs(game[category..'_prototypes']) do
--       self[object_name] = (pcall(function() return prot.group end))
--       break end
--     return self[object_name] end})
--   function get_full_prototype_order(prot)
--     return table.concat{
--       has_group[prot.object_name] and prot.group.order    or '',
--       has_group[prot.object_name] and prot.subgroup.order or '',
--       prot.order,
--       prot.name
--       }
--     end
--   end
  
-- V2
-- local get_full_prototype_order = function(prot)
--   return Prototype.get_absolute_order(prot.object_name, prot.name)
--   end
  
  
  
-- Creates a function that automatically calls a constructor
-- function f once. And returns the result of f() on all 
-- subsequent calls.
local function make_table_getter(f)
  local r1, r2, g
  function g() r1, r2 = f(); g = function() return r1, r2 end; return g() end
  return function() return g() end
  end

-- Creates an auto-resetting profiler or a dummy function.
local function get_profiler()
  return (not flag.IS_DEV_MODE) and ercfg.SKIP or (function(profiler)
    return function(msg) _ENV.log{'', msg, profiler}; profiler.restart() end
    end)(game.create_profiler())
  end
  
  
-- Pre-processes translated strings and user input
-- into an easy-to-compare form.
local normalize_word = function(word)
  return Utf8.lower(Utf8.remove_rich_text_tags(word))
  -- return utf8(word):remove_rich_text_tags():lower():tostring()
  end
  
-- -------------------------------------------------------------------------- --
-- Request Packet Preperation                                                 --
-- -------------------------------------------------------------------------- --

-- @treturn A DenseArray {request1, request2}
--          Sorted first by translation order and second by byte size.
--          Starting at most important translation and smallest size.
--          Each request contains a table of target entry specifications.
--
-- @treturn A PseudoSet mapping (type -> max_index).
--          The total number of entries for that type.
--
local get_ordered_requests = function()
  -- Prepare constants
  local OrderedRequestedTypes = (function(r) -- DenseArray
    for _, tdata in ipairs(const.type_data) do
      if RequestedTypes[tdata.type] then
        r[#r+1] = tdata.type
        end
      end
    return r end){}
  -- Prepare profiler
  local profile = get_profiler()
  -- Pre-sort required prototypes
  local sorted_prots = {}
  for _, type in ipairs(OrderedRequestedTypes) do
    if not sorted_prots[type] then
      local prots = {}
      local category = type:gsub('_[^_]+$','')
      for name, prot in pairs(game[category..'_prototypes']) do
        prots[#prots+1] = setmetatable({
          -- V1
          -- name = prot.name,
          -- real_order = get_full_prototype_order(prot), --12 times faster sorting
          -- V2
          name = name,
          real_order = Prototype.get_absolute_order(category, name)
          },{__index = prot})
        end
      table.sort(prots, function(a,b) return a.real_order < b.real_order end)
      sorted_prots[category..'_name'       ] = prots
      sorted_prots[category..'_description'] = prots
      end
    end
  profile('Prototype sorting took: ')
  --
  local function gtr_bytes(a, b) return a[rindex.bytes] > b[rindex.bytes] end
  local function lss_bytes(a, b) return a[rindex.bytes] < b[rindex.bytes] end
  local max_index       = {}
  local lookup          = {}
  local unique_requests = {}
  --
  for _, type in ipairs(OrderedRequestedTypes) do
    max_index[type] = #sorted_prots[type]
    --
    local arr = {}
    local lkey = type:gsub('^.*_', 'localised_')
    for index, prot in ipairs(sorted_prots[type]) do
      local entry = {
        [eindex.name ] = prot.name,
        [eindex.type ] = type,
        [eindex.index] = index,
        }
      --
      local lstring = prot[lkey]
      local ident   = lstring_ident(lstring)
      local request = lookup[ident]
      if request then
        table.insert(request[rindex.entries], entry)
      else
        request = {
          [rindex.lstring] = lstring,
          [rindex.bytes  ] = #ident + TypeBytes[type],
          [rindex.entries] = {entry}
          }
        lookup[ident ] = request
        arr   [#arr+1] = request
        end
      end
    table.sort(arr, lss_bytes)
    Array.extend(unique_requests, arr)
    -- profile(('Making %s requests took: '):format(type))
    end
  profile('Making ordered requests took: ')
  -- print(Hydra.lines(unique_requests, {indentlevel=1}))
  -- print(Hydra.lines(max_index))
  -- print('Unique request count:', #unique_requests)
  return unique_requests, max_index end
  
  
-- Packs the result of get_ordered_requests() into MTU sized
-- packets that each contain a localised string for player.request_translation
-- and a mapping of result entries.
--
-- @treturn A DenseArray {packed_requests1, packed_requests2}
--          Sorted by translation order. Most important LAST.
--
-- @treturn A PseudoSet mapping (type -> max_index).
--          The total number of entries for that type.
--          (Same as get_ordered_requests)
--
local get_request_packets = make_table_getter(function()
  -- const
  local max_packet_size = const.network.mtu_bytes
    - 8 -- babelfish header size
    - 8 -- outside transport overhead (assumption)
  local master_header = const.network.master_header
  local packet_header = const.network.packet_header.packed_request
  --
  local packets = {}
  local unique_requests, max_index = get_ordered_requests()
  local profile = get_profiler()
  --
  local packet, bytes, count, lstrings
  local function finalize_packet()
    packet[rindex.bytes  ] = bytes
    packet[rindex.lstring] = 
      {'', master_header, packet_header, null, packet[rindex.uid], null, Locale.compress(lstrings)}
    -- print(('Packet stat. Entries: %s, Bytes: %s'):format(#packet[rindex.entries], bytes))
    end
  local function new_packet()
    bytes = 0
    count = 0
    lstrings = {''}
    local index = #packets+1
    packet = {
      [rindex.entries] = {},
      [rindex.uid    ] = tostring(index),
      }
    packets[index] = packet
    end
  --
  new_packet()
  for i = #unique_requests, 1, -1 do
    local request = unique_requests[i]
    if (count > 0) and (bytes + request[rindex.bytes] > max_packet_size) then
      finalize_packet()
      new_packet()
      end
    bytes = bytes + request[rindex.bytes]
    count = count + 1
    table.insert(packet[rindex.entries], request[rindex.entries])
    table.insert(lstrings, request[rindex.lstring])
    table.insert(lstrings, null)
    end
  finalize_packet()
  profile('Packing requests together took: ')
  -- print(Hydra.lines(packets, {indentlevel=3}))
  -- print(Hydra.lines(max_index))
  -- print('Nubmer of packed packages: ', #packets)
  return packets, max_index end)

  
-- Cleans up stale entries (if any), then
-- requests a full retranslation.
function Dictionary:update()
  log:debug('Updating dictionary: ', self.language_code)
  --
  Table.clear(self, get_not_requested_search_types(), false)
  --
  local packets, max_index = get_request_packets()
  local profile = get_profiler()
  --
  self.packets     = Table.dcopy(packets)
  self.packets.max = #packets -- all-time maxium
  self.packets.n   = #packets -- current maximum
  self.packets.i   = #packets -- next package to be requested
  profile('Packets dcopy took: ')
  --
  if self.language_code == 'internal' then
    for type, max in pairs(max_index) do
      self[type] = {max = max}
      end
    self.packets.n = 0
    self.packets.i = 0
    for i = self.packets.max, 1, -1 do
      local packet = self.packets[i]
      self.packets[i] = nil
      for _, _, entry in ntuples(3, packet[rindex.entries]) do
        self[ entry[eindex.type] ][ entry[eindex.index] ] = {
          -- [eindex.word] = entry[eindex.name]:lower(),
          [eindex.word] = entry[eindex.name],
          [eindex.name] = entry[eindex.name],
          }
        end
      end
  --
  else
    local old_entries = {}
    for type, max in pairs(max_index) do
      old_entries[type] = self[type] and self[type].max and (function(r)
        for i=1, self[type].max do
          local entry = self[type][i]
          if entry then -- :update() during partial translation!
            r[ entry[eindex.name] ] = entry
            end
          end
        return r end){}
      --
      self[type] = {max = max} -- must exist before multi-type requests
      end
    --
    -- Most mod updates do not change the locale.
    -- For a smooth transition between mod versions the old
    -- translations are kept for searching while the
    -- retranslation process runs.
    for _, packet in ipairs(self.packets) do
      for _, _, entry in ntuples(3, packet[rindex.entries]) do
        local type  = entry[eindex.type ]
        local index = entry[eindex.index]
        local name  = entry[eindex.name ]
        if old_entries[type] and old_entries[type][name] then
          self[type][index] = {
            [eindex.word] = old_entries[type][name][eindex.word],
            [eindex.name] = name,
            -- [eindex.temp] = true,
            }
          end
        end
      end
    end
  --
  for type in pairs(max_index) do
    self:update_n(type)
    end
  --
  profile('Entry data cleanup took: ')
  end
  
-- -------------------------------------------------------------------------- --
-- Internal Names Dictionary                                                  --
-- -------------------------------------------------------------------------- --



-- function Dictionary.make_internal_names_dictionary()
  -- local self = Dictionary('internal')
  -- for _, packet in ipairs(self.packets) do
    -- for _, _, entry in ntuples(3, packet[rindex.entries]) do
      -- self[ entry[eindex.type] ][ entry[eindex.index] ] = {
        -- [eindex.word] = entry[eindex.name]:lower(),
        -- [eindex.name] = entry[eindex.name],
        -- }
      -- end
    -- end
  -- for i = 1, self.packets.max do 
    -- self.packets[i] = nil
    -- end
  -- return end

  
  
  
  
  
  
  
  
  
  
-- -------------------------------------------------------------------------- --
-- Debug                                                                      --
-- -------------------------------------------------------------------------- --
function Dictionary:dump_statistics_to_console()
  if assert(flag.IS_DEV_MODE) and (self.packets.n == 0) then
    print( ('-'):rep(80) )
    print( 'Dictionary Statistics:' )
    print( ('Language: %s'):format(self.language_code) )
    print( ('Total requests: %s'):format(self.packets.max) )
    print()
    print('Translated String Statistics:')
    -- print('Type | Longest | Shortest | Avearage | Mean | Unknown Key %')
    print('Type                         | Longest  | Shortest | Average  | Median   | Unk. Key')
    print()
    
    local function longest(arr)
      local n = 0
      for _, x in ipairs(arr) do n = (x > n) and x or n end
      return n end
      
    local function shortest(arr)
      local n = math.huge
      for _, x in ipairs(arr) do n = (x < n) and x or n end
      return n end
    
    local function average(arr)
      local r = 0
      for _, x in ipairs(arr) do r = r + x end
      return r/#arr end
      
    local function median(numlist)
      -- https://rosettacode.org/wiki/Averages/Median#Lua
      if type(numlist) ~= 'table' then return numlist end
      if #numlist == 0 then return 0/0 end
      table.sort(numlist)
      if #numlist %2 == 0 then return (numlist[#numlist/2] + numlist[#numlist/2+1]) / 2 end
      return numlist[math.ceil(#numlist/2)]
      end
    
    for _, tdata in ipairs(const.type_data) do
      local type = tdata.type
      if RequestedTypes[type] then
        local lengths = {}
        local untranslated = 0
        if not self[type] then
          game.print('Missing type. Use /babelfish update first.')
          return end
        for _, entry in ipairs(self[type]) do
          local lower = Utf8.lower(entry[eindex.word])
          table.insert(lengths, #lower)
          if Utf8.find(lower, 'unknown key') or (lower:gsub('%s+','') == '') then
            untranslated = untranslated + 1
            end
          end
        print( ('[%-26s] | %8s | %8s | %8.2f | %8.2f | %8.2f%%') :format(
          type,
          longest(lengths), shortest(lengths), average(lengths), median(lengths),
          100 * (untranslated / #lengths)
          ) )
        end
      end
    end
  end
  
-- -------------------------------------------------------------------------- --
-- Status                                                                     --
-- -------------------------------------------------------------------------- --

-- If the dictionary has anything left to request.
function Dictionary:has_requests()
  return (self.packets.n > 0) end
  
-- How much is translated yet. For informing the player.
function Dictionary:get_percentage()
  return math.floor(
    100 * (self.packets.max - self.packets.n)
    / self.packets.max )
  end

-- All keys have a translation, but some of the translations
-- may be outdated due to on_config_changed.
function Dictionary:is_type_fully_populated(type)
  return self[type].n == self[type].max end
  
-- Measures the length of the DenseArray part.
-- The SparseArray part I-n to I-max is ignored.
-- @treturn boolean if n changed at all.
function Dictionary:update_n(type)
  local this = assert(self[type])
  local old_n = this.n
  for i = this.n or 1, this.max do
    if this[i] then
      this.n = i
    else break end
    end
  if (old_n ~= this.max) and (this.n == this.max) then
    log:debug(('WIP: Fully populated %s of %s'):format(type, self.language_code))
    end
  return old_n ~= this.n end
  
-- @treturn boolean true if the state changed.
-- function Dictionary:update_is_fully_populated(type)
  -- local old_state = not not this.is_fully_populated
  -- this.is_fully_populated = (function()
    -- for i = this.max, 1, -1 do -- inverse finds false results faster.
      -- if not this[i] then return false end
      -- end
    -- return true end)()
  -- local has_state_changed
  -- if has_state_changed then
    -- end
  -- return (this.is_fully_populated ~= old_state) end

-- All translations are up-to-date.
-- function Dictionary:is_type_fully_translated(type)
  -- local this = self[type]
  -- if not this then return false end
  -- for i = this.max, 1, -1 do
    -- if (not this[i]) or this[i][eindex.temp] then return false end
    -- end
  -- return true end
  
-- function Dictionary:are_all_types_fully_translated()
  -- local types = get_requested_search_types()
  -- for i = 1, #types do
    -- if not self:is_type_fully_translated(types[i]) then return false end
    -- end
  -- return true end
  
-- -------------------------------------------------------------------------- --
-- Network                                                                    --
-- -------------------------------------------------------------------------- --
  
-- Does the CPU intensive setup of the internal lua state right now
-- to prevent lag spikes when a player joins later.
-- MUST NEVER CHANGE THE GAME STATE!
function Dictionary.precompile()
  Dictionary.precompile = ercfg.SKIP
  --
  get_request_packets()
  log:debug('Dictionary precompilation complete. (local lua state)')
  -- error('Precompile test OK')
  end
  
-- Iterator that waits a while after wrapping around.
function Dictionary:iter_packets(tick)
  return function()
    if (self.packets.i == 0) then
      self.packets.i = self.packets.n
      self.packets.block_iter_until = tick + const.network.rerequest_delay
      return nil end
    if (self.packets.block_iter_until or 0) < tick then
      self.packets.block_iter_until = nil
      --
      local packet = self.packets[self.packets.i]
      self.packets.i = self.packets.i - 1
      -- print(('Iter: Entries %s, Bytes %s'):format(
        -- #packet[rindex.entries], packet[rindex.bytes]
        -- ))
      return packet[rindex.lstring], packet[rindex.bytes]
      end
    end
  end
  
  
-- Event data must be filtered for correct header + id before
-- being passed here.
--
-- @treturn number The difference between the heuristically estimated
--                 size of the result and the real size recieved.
--                 As Babelfish attempts to never underestimate
--                 this is usually a positive number (overestimated).
--
function Dictionary:on_string_translated(lstrings, results)
  if self.packets.n == 0 then 
    log:debug('Recieved results but had no open requests: ', results)
    return end
  --
  -- results → {header+id, uid, result1, result2}
  local next   = string_gmatch(results,'\0([^\0]+)') -- faster than String.split
  local uid = next()
  --
  local i = self.packets.n + 1;
  repeat i = i - 1; until (i == 0) or (
    (uid == self.packets[i][rindex.uid])
    and equ_lstring(self.packets[i][rindex.lstring], lstrings)
    )    
  --
  if not self.packets[i] then
    print('Self:')
    print('equ to n?', equ_lstring(self.packets[self.packets.n][rindex.lstring], lstrings))
    print('uid?', uid, self.packets[self.packets.n][rindex.uid])
    print('Index:', i)
    -- print(Hydra.lines(self,{indentlevel=4}))
    print(Hydra.lines(self.packets[self.packets.n][rindex.lstring]))
    print(('Packets n=%s, i=%s, max=%s, #=%s'):format(
      self.packets.n, self.packets.i, self.packets.max, #self.packets
      ))
    print('Event data:')
    print(Hydra.lines(lstrings))
    print(Hydra.lines(results))
    end
  --
  -- Unsorted remove. If package loss is high this might
  -- disturb the translation type order, but it's significantly
  -- faster than iterating the whole array all the time.
  local packet = assert(Array.shuffle_pop(self.packets, i), 'Packet not found!')
  self.packets.n = self.packets.n - 1
  self.packets.i = math.min(self.packets.i, self.packets.n)
  --
  -- Re-Lookup the estimated portion of the packet size
  -- to allow for more precise bitrate control by comparison
  -- with the real result size.
  local estimated_result_bytes = 0
  --
  local j, result, entries = 0, next(), packet[rindex.entries]
  local packet_types = {}
  repeat; j = j + 1
    estimated_result_bytes = 
      estimated_result_bytes + TypeBytes[entries[j][1][eindex.type]]
    if result == nil then
      -- Seen for item_subgroup_name and at least one achievement.
      -- All other functions assume result is of type string.
      result = ''
      log:debug('Translation result was nil: ', entries)
      end
    for _, entry in ipairs(entries[j]) do
      packet_types[entry[eindex.type]] = true
      --
      -- The engine translates unknown descriptions as "unknown key"
      -- but unlike unknown item names vanilla shows them as empty.
      -- Not storing them saves space and fixes search results.
      if string_find(entry[eindex.type], '_description') then 
        local t = string_gsub(entry[eindex.type],'_','-')
        if result == 'Unknown key: "'..t..'.'..entry[eindex.name]..'"' then
          if flag.IS_DEV_MODE then
            -- Length has to be preserved for dump_statistics()
            -- but search results should be kept clean.
            result = (' '):rep(#result)
          else
            result = ''
            end
          end
        end
      --
      -- This should always *replace* the whole entry
      -- to ensure smooth migration if the indexes ever change.
      self[ entry[eindex.type] ][ entry[eindex.index] ] = {
        -- [eindex.word] = string_lower(remove_rich_text_tags(result)),
        [eindex.word] = result,
        [eindex.name] = entry[eindex.name],
        -- [eindex.temp] = nil, -- remove flag
        }
      -- print(Hydra.line{entry[eindex.type],self[ entry[eindex.type] ][ entry[eindex.index] ]})
      end
    result = next()
    until not result
  assert(j == #entries, 'Wrong result count.')
  --
  local has_state_changed = false
  for type in pairs(packet_types) do
    if self:update_n(type) and self:is_type_fully_populated(type) then
      has_state_changed = true
      end
    end
  --
  return estimated_result_bytes, packet[rindex.bytes], has_state_changed end

  
-- -------------------------------------------------------------------------- --
-- Find + Search                                                              --
-- -------------------------------------------------------------------------- --

--[[ Notes on wont-implement option ideas:

  + Array result format is not faster than set to construct because
    to construct an array of *unique* entries a set would be required anyway.
    And an array with duplicate entries isn't useful.

  + Merging result types is not useful because it would only produce
    meaningful results for pairs of name+desc types, and complete
    garbage when used with anything else.
    
  ]]

-- User-input should not be cached to prevent
-- high memory usage or exploits.
local normalized_word_cache = Memoize(normalize_word) -- language agnostic!
  
-- Some malformed patterns do not fail if they
-- don't actually have any matches in the input string.
-- (This very likely still has false positives.)
local ascii_array = (function(r)
  for i=1, 255 do r[i] = string.char(i) end
  return table.concat(r) end){}
local function is_well_formed_pattern(word)
  if word:sub(-1) ~= '%' then
    return (pcall(string_find, ascii_array, word))
  else return false end end
  
-- Replaces all space by ascii space, then splits.
local function split_by_space(ustr)
  for _, space in pairs(String.UNICODE_SPACE) do
    ustr = ustr:gsub(space,' ')
    end
  return String.split(ustr, '%s+') end

local matchers = {}
function matchers.plain (t,ws)
    for i=1,#ws do if not utf8_find(t,ws[i],1,true) then return false end end
    return true end
  
  
-- @tparams types DenseArray {'item_name', 'recipe_name',...}
-- @tparams string word The search term.
-- @params table opt Options
-- 
-- @treturn boolean This only returns true if translation is incomplete.
-- @treturn table|nil 
--
function Dictionary:find(types, word, opt)
  verify(types    , 'table' , 'Babelfish: Invalid "types" format.'   )
  verify(word     , 'string', 'Babelfish: Invalid "word" format.'    )
  verify(opt      , 'table' , 'Babelfish: Invalid "options" format.' )
  verify(opt.limit, 'nil|Integer', 'Babelfish: Invalid limit.' )
  --
  local n = opt.limit and opt.limit or math.huge
  local r = {}
  local exact_word = word
  local status = true
  --
  local matcher
  if opt.mode == 'lua' then
    -- Lua mode can fail with "weird" user input.
    -- But that case needs to behave like a search without results.
    matcher = is_well_formed_pattern(word) and string_find or Filter.FALSE
  elseif opt.mode == 'fuzzy' then
    matcher = Utf8.find_fuzzy
    -- word = String.to_array(String.remove_whitespace(word:lower()))
    word = Utf8.to_array(Utf8.remove_whitespace(Utf8.lower(word)))
  else
    matcher = matchers.plain
    -- word = split_by_space(word:lower())
    word = split_by_space(Utf8.lower(word))
    end
  --
  for i=1, #types do
    local type = types[i]
    assertify(SupportedTypes[type], 'Babelfish: Invalid translation type: ', type)
    assertify(RequestedTypes[type], 'Babelfish: Type must be configured in settings stage: ', type)
    -- This will only fail on new maps or after an :update()
    -- added new prototypes.
    -- if (table_size(self[type]) - 1) ~= self[type].max then status = false end
    if not self:is_type_fully_populated(type) then status = false end
    -- subtables are created regardless of n
    local this = {}; r[type] = this
    for i = 1, self[type].max do
      if n <= 0 then break end
      local entry = self[type][i]
      if entry then -- self[type] is sparse after :update()
        local name = entry[eindex.name]
        if (exact_word == name) -- verbatim internal name match
        -- or matcher(entry[eindex.word], word) then
        or matcher(normalized_word_cache[entry[eindex.word]], word) then
          n = n - 1
          this[name] = (not flag.IS_DEV_MODE) or entry[eindex.word]
          end
        end
      end
    end
  -- Pssst! ;)
  -- if (exact_word:lower() == 'dolphin')
  if (Utf8.lower(exact_word) == 'dolphin')
  and r.item_name
  and game.item_prototypes['raw-fish']
  then r.item_name['raw-fish'] = true end
  --
  if flag.IS_DEV_MODE then
    log:debug('Cache size: ', table_size(normalized_word_cache))
    end
  --
  return status, r end

  
-- There is no distinction between "that name isn't translated"
-- and "that is not a prototype name". Even erroring on invalid
-- names would incur a heavy performance penalty on every call.
--
-- Only translates one name at a time to discourage
-- authors from mass-caching the results!
function Dictionary:translate_name(type, name)
  assertify(SupportedTypes[type], 'Babelfish: Invalid translation type: ', type)
  assertify(RequestedTypes[type], 'Babelfish: Type must be configured in settings stage: ', type)
  verify(name, 'str', 'Babelfish: Invalid name: ', name)
  local this = self[type]
  for i = 1, self[type].max do
    if this[i] and (this[i][eindex.name] == name) then
      return this[i][eindex.word]
      end
    end
  end
  
  
return Dictionary