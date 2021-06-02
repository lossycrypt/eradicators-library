-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
-- -------------------------------------------------------------------------- --

--[[ Keep it simple:

  Babelfish does the heavy lifting regarding translation. But the
  search function should only supply a minimal interface to build mods on.
  
  ]]

--[[ Won't implement:
  
  Mods can combine search results as they see fit. Babelfish wont
  do specific combinations like "search recipe and ingredients and products".
  
  ]]


--[[ Future Possibilities:

  + Cache find resulsts instead of "lower" strings
    to reduce global data at cost of local data?
  
  + Filter out useless entity prototypes. (explosions, projectiles, etc)
  
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
                                                
local String      = elreq('erlib/lua/String'    )()
local Class       = elreq('erlib/lua/Class'     )()
local Filter      = elreq('erlib/lua/Filter'    )()

local Cache       = elreq('erlib/factorio/Cache' )()
local Locale      = elreq('erlib/factorio/Locale')()

local Table       = elreq('erlib/lua/Table'     )()
local Array       = elreq('erlib/lua/Array'     )()
local Set         = elreq('erlib/lua/Set'       )()

local sriapi      = elreq('erlib/lua/Iter/sriapi' )()
local dpairs      = elreq('erlib/lua/Iter/dpairs' )()
local ntuples     = elreq('erlib/lua/Iter/ntuples')()

local pairs, pcall, string_find, type
    = pairs, pcall, string.find, type
    
-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local import = PluginManager.make_relative_require'babelfish'
local const  = import '/const'
local ident  = serpent.line

local SupportedTypes = const.type_bytes_estimate -- PseudoSet
  
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
  index   = 4,
  }
  
-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Dictionary = Class.SimpleClass(
  -- initializer
  function(language_code)
    local self = {
      language_code
        = language_code,
      native_language_name
        = assert(const.native_language_name[language_code], 'Invalid language_code'),
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
-- Result is identical to serpent.line(lstring).
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
  return table.concat(f(lstring, {}))
  end
  
-- Pre-calculating the full order string makes sorting 12 times faster.
local get_full_prototype_order; do
  local has_group = setmetatable({},{__index=function(self, object_name)
    local category = object_name:match('Lua(.+)Prototype'):lower()
    for _, prot in pairs(game[category..'_prototypes']) do
      self[object_name] = (pcall(function() return prot.group end))
      break end
    return self[object_name] end})
  function get_full_prototype_order(prot)
    return table.concat {
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
  local TypeBytes = {}
  local OrderedRequestedTypes = (function(r) -- DenseArray
    for _, tdata in ipairs(const.type_data) do
      if RequestedTypes[tdata.type] then
        r[#r+1] = tdata.type
        TypeBytes[tdata.type] = tdata.longest
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
  local null = '\0'
  local header = const.network.packed_request_header
  --
  local packets = {}
  local unique_requests, max_index = get_ordered_requests()
  local profile = get_profiler()
  --
  local packet, bytes, count
  local function finalize_packet()
    packet[rindex.lstring] = Locale.merge(table.unpack(packet[rindex.lstring]))
    packet[rindex.bytes  ] = bytes
    -- print(('Packet stat. Entries: %s, Bytes: %s'):format(#packet[rindex.entries], bytes))
    end
  local function new_packet()
    bytes = 0
    count = 0
    local index = #packets+1
    packet = {
      [rindex.lstring] = {header, null, index, null},
      [rindex.entries] = {},
      [rindex.index  ] = index,
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
    table.insert(packet[rindex.lstring], request[rindex.lstring])
    table.insert(packet[rindex.lstring], null)
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
  local profile = get_profiler()
  local packets, max_index = get_request_packets()
  profile('Packets preparation took (total): ')
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
  for type, max in pairs(max_index) do
    --
    local old_entries = self[type] and (function(r)
      for i=1, self[type].n do
        local entry = self[type][i]
        r[ entry[eindex.name] ] = entry
        end
      return r end){}
    --
    self[type] = {n = max}
    -- Most mod updates do not change the locale.
    -- For a smooth transition between mod versions the old
    -- translations are stored for searching while the
    -- retranslation process runs.
    if old_entries then
      for _, packet in ipairs(packets) do
        for _, _, entry in ntuples(3, packet.entries) do
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
  profile('Entry data cleanup took: ')
  end
  
-- -------------------------------------------------------------------------- --
-- Internal Names Dictionary                                                  --
-- -------------------------------------------------------------------------- --

function Dictionary.make_internal_names_dictionary()
  local self = Dictionary('internal')
  for _, packet in ipairs(self.packets) do
    for _, _, entry in ntuples(3, packet.entries) do
      self[ entry[eindex.type] ][ entry[eindex.index] ] = {
        [eindex.lower] = entry[eindex.name]:lower(),
        [eindex.name ] = entry[eindex.name],
        }
      end
    end
  for i = 1, self.packets.max do 
    self.packets[i] = nil
    end
  return end

  
  
  
  
  
  
  
  
  
  
-- -------------------------------------------------------------------------- --
-- Debug                                                                      --
-- -------------------------------------------------------------------------- --
function Dictionary:dump_statistics_to_console()
  if flag.IS_DEV_MODE and (self.requests.n == 0) then
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
        for name, data in pairs(self[type]) do
          local lower = data[eindex.lower]
          table.insert(lengths, #lower)
          if lower:find('Unknown Key') then
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

function Dictionary:can_translate(type)
  assertify(RequestedTypes[type], 'Babelfish: Invalid translation type: ', type)
  return (table_size(self[type]) - 1) == self[type].n end
  
-- -------------------------------------------------------------------------- --
-- Network                                                                    --
-- -------------------------------------------------------------------------- --
  
  
function Dictionary.precompile()
  Dictionary.precompile = ercfg.SKIP
  --
  Dictionary('en')
  error('Precompile test OK')
  end
  
function Dictionary:recieve_packet()
  
  end
  
  
function Dictionary:request_packet(request_translation, max_bytes)

  local packet
  repeat 
    packet = self.packets[self.packets.i]
    
    -- tomorrow: remove index etc for Array.unsorted_remove()
    
    

    until false --???
  
  -- self.packets.i
  end
  
  
-- -------------------------------------------------------------------------- --
-- Network                                                                    --
-- -------------------------------------------------------------------------- --
  
  
  
-- Store the result of an on_string_translated event
-- into the dictionary. When other mods also send requests
-- unwanted garbage must be filtered out.
function Dictionary:push_translation(lstring, translation)
  -- naive
  -- local id = ident(lstring)
  -- local request = self.lookup[id]
  -- noident
  local request
  local requests = self.requests
  local i = self.requests.n + 1
  repeat i = i - 1
  -- for i = self.requests.n, 1, -1 do
    if lstring_is_equal(requests[i].lstring, lstring) then
      -- print('Ident after '..(self.requests.n - i))
      request = requests[i]
      break
      end
    until i == 1
  assert(request or i == 1, 'Noident failed')
  --
  if request then
    -- self.lookup[id] = nil
    --
    -- Unsorted remove. If package loss is high this might
    -- disturb the translation type order, but it's significantly
    -- faster than iterating the whole array all the time.
    self.requests[request.i] = self.requests[self.requests.n]
    self.requests[self.requests.n] = nil
    self.requests.n = self.requests.n - 1
    --
    for _, entry in pairs(request.entries) do
      self.open_requests[entry.type] = self.open_requests[entry.type] - 1
      if translation == false then
        self[entry.type][entry.name] = {
          [index.localised] = false,
          [index.lower    ] = nil, -- reduce Savedata, store no garbage
          }
      else
        self[entry.type][entry.name] = {
          [index.localised] = true,
          [index.lower    ] = String.remove_rich_text_tags(translation):lower(),
          }
        end
      end
    end
  end

-- When max_bytes is smaller than the first request
-- in the queue no reuqests will be sent at all.  
function Dictionary:dispatch_requests(p, max_bytes)
  local bytes, tick, i = 0, game.tick, self.requests.n
  for i = self.requests.n, 1, -1 do
    local request = assert(self.requests[i])
    if (request.next_request_tick < tick) then
      if (bytes + request.bytes) > max_bytes then break end
      bytes = bytes + request.bytes
      p.request_translation(request.lstring)
      request.next_request_tick = tick + const.network.rerequest_delay
      end
    i = i - 1
    end
  return bytes end


function Dictionary:collect_packets(f, max_bytes)
  local bytes, tick, i = 0, game.tick, self.requests.n
  local packet_count = 0
  for i = self.requests.n, 1, -1 do
    local request = assert(self.requests[i])
    if (request.next_request_tick < tick) then
      if (packet_count > 18)
      or ((bytes + request.bytes) > max_bytes) then break end
      packet_count = packet_count + 1
      --
      bytes = bytes + request.bytes
      -- p.request_translation(request.lstring)
      f(request.lstring)
      request.next_request_tick = tick + const.network.rerequest_delay
      end
    i = i - 1
    end
  return bytes end
  
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
  --
  -- fuzzy + lua modes can crash with "weird" user input.
  -- But this needs to fail independantly of self.open_requests.
  local matcher
  if opt.mode == 'lua' then
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
    if self.open_requests[type] ~= 0 then return false, nil end
    local this = {}; r[type] = this
    for name, translation in pairs(self[type]) do
      if  (n > 0)
      and translation[index.localised]
      and matcher(translation[index.lower], word) then
        this[name], n = true, n - 1
        end
      end
    end
  -- Pssst! ;)
  if ((word[1] or word) == 'dolphin')
  and r.item_name
  and game.item_prototypes['raw-fish']
  then r.item_name['raw-fish'] = true end
  --
  return true, r end

  
return Dictionary