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
  
  + Filter out useless entity prototypes. (explosions, projectiles, etc)
  
  + Exclude "Unknown Key:" /descriptions/ from find()
    because those are not shown in-game. (Unlike unknown item names.)
    But only if it matches *exactly* the expected
    <Unknown Key: "type-description.prototype-name"> including correct
    capitalization! (Probably best not to store it at all)
    
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
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))
-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
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
local remove_rich_text_tags = String.remove_rich_text_tags

local Table       = elreq('erlib/lua/Table'     )()
local Array       = elreq('erlib/lua/Array'     )()
local Set         = elreq('erlib/lua/Set'       )()

local sriapi      = elreq('erlib/lua/Iter/sriapi' )()
local dpairs      = elreq('erlib/lua/Iter/dpairs' )()
local ntuples     = elreq('erlib/lua/Iter/ntuples')()

local Cache       = elreq('erlib/factorio/Cache'  )()
local Locale      = elreq('erlib/factorio/Locale' )()
local Setting     = elreq('erlib/factorio/Setting')()

local pairs, pcall, string_find, type, string_gmatch, string_lower
    = pairs, pcall, string.find, type, string.gmatch, string.lower
    
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
  
local RequestedTypes = Cache.AutoCache(function(r) -- PseudoSet
  for k, v in ipairs(
  game.mod_setting_prototypes[const.setting_name.search_types].allowed_values)
  do r[v] = true end
  end)

-- -------------------------------------------------------------------------- --
-- Indexes                                                                    --
-- -------------------------------------------------------------------------- --
local eindex = { -- Entry data index
  name  = 2,
  -- translated entries only
  lower = 1,
  -- requested entries only
  index = 3,
  type  = 4,
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
local mt_lstring_indexed_array = {
  __index = function(self, lstring)
    for i=#self, 1, -1  do
      local v = self[i] -- might require rawget or setmetatable(self, nil)
      if equ_lstring(v[1], lstring) then return v end
      end
    end,
  }

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
local function lstring_compact(lstring)
  -- Example:
  -- 5 == #{'',1,2,3,4} 
  -- 3 == #{'',{'',1,2},{'',3,4}}
  -- 2 == #{'',{'',{'',1,2},{'',3,4}}}
  --
  assertify(lstring[1] == '', 'Uncompressible lstring: ', lstring)
  local function f ()
    local k = 1
    for i=2, #lstring, 20 do
      k = k + 1
      local t = {''}
      for j=0, 19 do
        t[j+2] = lstring[i+j]
        lstring[i+j] = nil
        end
      lstring[k] = t
      end
    end
  while #lstring > 21 do f() end
  return lstring end

  
  
-- Pre-calculating the full order string makes sorting 12 times faster.
local get_full_prototype_order; do
  local has_group = setmetatable({},{__index=function(self, object_name)
    local category = object_name:match('Lua(.+)Prototype'):lower()
    for _, prot in pairs(game[category..'_prototypes']) do
      self[object_name] = (pcall(function() return prot.group end))
      break end
    return self[object_name] end})
  function get_full_prototype_order(prot)
    return table.concat{
      has_group[prot.object_name] and prot.group.order    or '',
      has_group[prot.object_name] and prot.subgroup.order or '',
      prot.order,
      prot.name
      }
    end
  end
  
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
      for name, prot in pairs(game[type:gsub('_.*$','_prototypes')]) do
        prots[#prots+1] = setmetatable({
          real_order = get_full_prototype_order(prot), --12 times faster sorting
          name = prot.name,
          },{__index = prot})
        end
      table.sort(prots, function(a,b) return a.real_order < b.real_order end)
      sorted_prots[type:gsub('_.*$','_name'       )] = prots
      sorted_prots[type:gsub('_.*$','_description')] = prots
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
      {'', master_header, packet_header, null, packet[rindex.uid], null, lstring_compact(lstrings)}
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
  local packets, max_index = get_request_packets()
  local profile = get_profiler()
  --
  self.packets     = Table.dcopy(packets)
  self.packets.max = #packets -- all-time maxium
  self.packets.n   = #packets -- current maximum
  self.packets.i   = #packets -- next package to be requested
  profile('Packets dcopy took: ')
  --
  for _, tdata in pairs(const.type_data) do
    if not RequestedTypes[tdata.type] then
      self[tdata.type] = nil
      end
    end
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
          [eindex.lower] = entry[eindex.name]:lower(),
          [eindex.name ] = entry[eindex.name],
          }
        end
      end
  --
  else
    for type, max in pairs(max_index) do
      --
      local old_entries = self[type] and self[type].max and (function(r)
        for i=1, self[type].max do
          local entry = self[type][i]
          r[ entry[eindex.name] ] = entry
          end
        return r end){}
      --
      self[type] = {max = max}
      --
      -- Most mod updates do not change the locale.
      -- For a smooth transition between mod versions the old
      -- translations are kept for searching while the
      -- retranslation process runs.
      if old_entries then
        for _, packet in ipairs(packets) do
          for _, _, entry in ntuples(3, packet[rindex.entries]) do
            local type  = entry[eindex.type ]
            local index = entry[eindex.index]
            local name  = entry[eindex.name ]
            if old_entries[name] then
              self[type][index] = {
                [eindex.lower] = old_entries[name][eindex.lower],
                [eindex.name ] = name,
                }
              end
            end
          end
        end
      end
    end
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
        -- [eindex.lower] = entry[eindex.name]:lower(),
        -- [eindex.name ] = entry[eindex.name],
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
  if flag.IS_DEV_MODE and (self.packets.n == 0) then
    print( ('-'):rep(80) )
    print( 'Dictionary Statistics:' )
    print( ('Language: %s'):format(self.language_code) )
    print( ('Total requests: %s'):format(self.packets.max) )
    print()
    print('Translated String Statistics:')
    -- print('Type | Longest | Shortest | Avearage | Mean | Unknown Key %')
    print('Type                     | Longest  | Shortest | Average  | Median   | Unk. Key')
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
        for _, entry in ipairs(self[type]) do
          local lower = entry[eindex.lower]
          table.insert(lengths, #lower)
          if lower:find('unknown key') then
            untranslated = untranslated + 1
            end
          end
        print( ('[%-22s] | %8s | %8s | %8.2f | %8.2f | %8.2f%%') :format(
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

-- function Dictionary:can_translate(type)
  -- assertify(RequestedTypes[type], 'Babelfish: Invalid translation type: ', type)
  -- return (table_size(self[type]) - 1) == self[type].max end
  
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
  repeat; j = j + 1
    estimated_result_bytes = 
      estimated_result_bytes + TypeBytes[entries[j][1][eindex.type]]
    for _, entry in ipairs(entries[j]) do
      self[ entry[eindex.type] ][ entry[eindex.index] ] = {
        [eindex.lower] = string_lower(remove_rich_text_tags(result)),
        [eindex.name ] = entry[eindex.name],
        }
      -- print(Hydra.line{entry[eindex.type],self[ entry[eindex.type] ][ entry[eindex.index] ]})
      end
    result = next()
    until not result
  assert(j == #entries, 'Wrong result count.')
  --
  return estimated_result_bytes, packet[rindex.bytes] end
  

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
  
  

-- Replaces all space by ascii space, then splits.
local function split_by_space(ustr)
  for _, space in pairs(String.UNICODE_SPACE) do
    ustr = ustr:gsub(space,' ')
    end
  return String.split(ustr, '%s+') end

local matchers = {}
function matchers.plain (t,ws)
    for i=1,#ws do if not string_find(t,ws[i],1,true) then return false end end
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
  -- local eindex_lower = (self.language_code ~= 'internal')
                      -- and eindex.lower or eindex.name
  --
  local matcher
  if opt.mode == 'lua' then
    -- Lua mode can fail with "weird" user input.
    -- But this needs to behave like a search without results.
    matcher = (pcall(string_find,'',word)) and string_find or Filter.False
  elseif opt.mode == 'fuzzy' then
    matcher = String.find_fuzzy
    word = String.to_array(String.remove_whitespace(word:lower()))
  else
    matcher = matchers.plain
    word = split_by_space(word:lower())
    end
  --
  for i=1, #types do
    local type = types[i]
    assertify(SupportedTypes[type], 'Babelfish: Invalid translation type: ', type)
    assertify(RequestedTypes[type], 'Babelfish: Type must be configured in settings stage: ', type)
    -- This will only fail on new maps or after an :update()
    -- added new prototypes.
    if (table_size(self[type]) - 1) ~= self[type].max then status = false end
    -- subtables are created regardless of n
    local this = {}; r[type] = this
    for i = 1, self[type].max do
      if n <= 0 then break end
      local entry = self[type][i]
      if entry then -- self[type] is sparse after :update()
        local name = entry[eindex.name]
        if (exact_word == name) -- verbatim internal name match
        or matcher(entry[eindex.lower], word) then
          n = n - 1
          this[name] = (not flag.IS_DEV_MODE) or entry[eindex.lower]
          end
        end
      end
    end
  -- Pssst! ;)
  if (exact_word:lower() == 'dolphin')
  and r.item_name
  and game.item_prototypes['raw-fish']
  then r.item_name['raw-fish'] = true end
  --
  return status, r end

  
return Dictionary