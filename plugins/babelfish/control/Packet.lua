-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
-- -------------------------------------------------------------------------- --

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
local log         = elreq('erlib/lua/Log'          )().Logger  'babelfish'
-- local stop        = elreq('erlib/lua/Error'        )().Stopper 'babelfish'
-- local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

-- local Verificate  = elreq('erlib/lua/Verificate'   )()
-- local verify      = Verificate.verify
-- local isType      = Verificate.isType

local Table       = elreq('erlib/lua/Table'        )()
-- local Array       = elreq('erlib/lua/Array'        )()
-- local Set         = elreq('erlib/lua/Set'          )()
-- local Filter      = elreq('erlib/lua/Filter'       )()
-- local Vector      = elreq('erlib/lua/Vector'       )()

-- local ntuples     = elreq('erlib/lua/Iter/ntuples' )()
-- local dpairs      = elreq('erlib/lua/Iter/dpairs'  )()
-- local sriapi      = elreq('erlib/lua/Iter/sriapi'  )()

local Locale      = elreq('erlib/factorio/Locale'    )()
-- local Setting     = elreq('erlib/factorio/Setting'   )()
-- local Player      = elreq('erlib/factorio/Player'    )()
-- local getp        = Player.get_event_player

local string_gmatch
    = string.gmatch

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
-- local script = EventManager .get_managed_script    'babelfish'
local import = PluginManager.make_relative_require 'babelfish'
local const  = import '/const'

local rindex = const.index.request

local null = '\0'

local RawEntries       = import '/control/RawEntries'


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Packet = {}

-- -------------------------------------------------------------------------- --
-- Savedata                                                                   --
-- -------------------------------------------------------------------------- --
local Savedata
PluginManager.manage_savedata  ('babelfish', function(_) Savedata = _ end)

-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --

--[[ Note:

  request_uid is stored in savedata, but RawEntries.requests are AutoCache!
  Is there a possible situation where this would cause problems?

  ]]

function Packet.get_uid()
  Savedata.packets.n = (Savedata.packets.n or 0) + 1
  return Savedata.packets.n
  end

do
    
  function Packet.send(p, dict, count)
    local index = Packet.get_uid()
    local nlstrings = Table.set(Savedata.packets, {index}, {})
    --
    local i, packet = 1, {''}
    local next = dict:iter_requests()
    for j=i+1, i+count*2, 2 do
      local request = next()
      if not request then break end
      table.insert(nlstrings, request[rindex.lstring])
      packet[j  ] = null
      packet[j+1] = request[rindex.lstring]
      end
    --
    if #packet > 1 then -- dict re-request pause
      p.request_translation{
        '',
        const.network.master_header,
        const.network.packet_header.packed_request,
        index,
        -- header , 
        Locale.compress(packet)
        }
      end
    end
  end
  
function Packet.unpack(dict, e)
  local packet  = e.localised_string
  local results = e.result

  -- print(Hydra.lines(packet))
  
  assert(packet[1] == '')
  assert(packet[2] == const.network.master_header)
  assert(packet[3] == const.network.packet_header.packed_request)
  -- assert(packet[5] == null)
  
  local nlstrings = Table.pop(Savedata.packets, assert(tonumber(packet[4])))
  if not nlstrings then
    log:debug('Recieved packed request with unknown index.')
  else
    local i = 0
    for word in string_gmatch(results, '\0([^\0]*)') do
      i = i + 1
      dict:set_lstring_translation(nlstrings[i], word)
        -- RawEntries.requests[nlstrings[i]][rindex.lstring], word)
      end
    assert(i == #nlstrings, 'Incorrect packet length.')
    log:debugf('Pack.unpack unpacked %s requests', i)
    end
  end

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  

-- -------------------------------------------------------------------------- --
-- OLD STUFF BELOW THIS                                                       --
-- -------------------------------------------------------------------------- --
if true then return Packet end


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
  -- local OrderedRequestedTypes = (function(r) -- DenseArray
    -- for _, tdata in ipairs(const.type_data) do
      -- if RequestedTypes[tdata.type] then
        -- r[#r+1] = tdata.type
        -- end
      -- end
    -- return r end){}
  -- Prepare profiler
  local profile = Local.get_profiler()
  -- Pre-sort required prototypes
  local sorted_prots = {}
  for _, type in SearchTypes.requested_ipairs() do
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
  for _, type in SearchTypes.requested_ipairs() do
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
  
  
local get_ordered_requests = function()
  return Table.dcopy(RawEntries.requests), Table.dcopy(RawEntries.max_indexes)
  end
  
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
  local profile = Local.get_profiler()
  --
  local packet, bytes, count, lstrings
  local function finalize_packet()
    packet[rindex.bytes  ] = bytes
    packet[rindex.lstring] = 
      -- {'', master_header, packet_header, null, packet[rindex.uid], null, Locale.compress(lstrings)}
      {'', master_header, packet_header, null, packet[rindex.uid], Locale.compress(lstrings)}
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
    table.insert(lstrings, null) -- final translated result may never end with null
    table.insert(lstrings, request[rindex.lstring])
    end
  finalize_packet()
  profile('Packing requests together took: ')
  -- print(Hydra.lines(packets, {indentlevel=3}))
  -- print(Hydra.lines(max_index))
  -- print('Nubmer of packed packages: ', #packets)
  return packets, max_index end)


  
-- -------------------------------------------------------------------------- --
-- Network                                                                    --
-- -------------------------------------------------------------------------- --


  
-- Event data must be filtered for correct header + id before
-- being passed here.
--
-- @treturn number The difference between the heuristically estimated
--                 size of the result and the real size recieved.
--                 As Babelfish attempts to never underestimate
--                 this is usually a positive number (overestimated).
--
function Dictionary:on_string_translated(lstrings, results)
  if self.request_uids.n == 0 then 
    log:debug('Recieved results but had no open requests: ', results)
    return end
  --
  -- gmatch parsing will produce one result too much
  -- if there's a superfluous null at the end.
  assert(string_sub(results, -1) ~= null, 'Result packet must not end with "null".')
  --
  -- results → {header+id, uid, result1, result2}
  -- (sequence {null,'',null} must return the empty string in-between.)
  local next   = string_gmatch(results,'\0([^\0]*)') -- faster than String.split
  local uid = next()
  --
  local i = self.request_uids.n + 1;
  repeat i = i - 1; until (i == 0) or (
    (uid == self.request_uids[i][rindex.uid])
    and lstring_is_equal(self.request_uids[i][rindex.lstring], lstrings)
    )    
  --
  if not self.request_uids[i] then
    print('Self:')
    print('equ to n?', lstring_is_equal(self.request_uids[self.request_uids.n][rindex.lstring], lstrings))
    print('uid?', uid, self.request_uids[self.request_uids.n][rindex.uid])
    print('Index:', i)
    -- print(Hydra.lines(self,{indentlevel=4}))
    print(Hydra.lines(self.request_uids[self.request_uids.n][rindex.lstring]))
    print(('Packets n=%s, i=%s, max=%s, #=%s'):format(
      self.request_uids.n, self.request_uids.i, self.request_uids.max, #self.request_uids
      ))
    print('Event data:')
    print(Hydra.lines(lstrings))
    print(Hydra.lines(results))
    end
  --
  -- Unsorted remove. If package loss is high this might
  -- disturb the translation type order, but it's significantly
  -- faster than iterating the whole array all the time.
  local packet = assert(Array.shuffle_pop(self.request_uids, i), 'Packet not found!')
  self.request_uids.n = self.request_uids.n - 1
  self.request_uids.i = math.min(self.request_uids.i, self.request_uids.n)
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

