-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable
-- -------------------------------------------------------------------------- --
  
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

local Table       = elreq('erlib/lua/Table'        )()

local Locale      = elreq('erlib/factorio/Locale'    )()

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

-- Temporary unique id for a packet.
-- Only valid for one dict. Will be reset after dict is complete.
function Packet.get_uid()
  Savedata.packets.n = (Savedata.packets.n or 0) + 1
  return Savedata.packets.n
  end


function Packet.send(p, dict, count)
  local index = Packet.get_uid()
  local nlstrings = Table.set(Savedata.packets, {index}, {})
  --
  local i, packet = 1, {''}
  local next = dict:iter_requests()
  for j=i+1, i+count*2, 2 do
    local request = next()
    if not request then break end -- beware count == math.huge!
    table.insert(nlstrings, request[rindex.lstring])
    packet[j  ] = null
    packet[j+1] = request[rindex.lstring]
    end
  --
  if #packet > 1 then -- dict re-request pause
    p.request_translation{
      '',
      -- header
      const.network.master_header,
      const.network.packet_header.packed_request,
      index,
      -- payload
      Locale.compress(packet)
      }
    end
  end


function Packet.unpack(dict, e)
  local packet  = e.localised_string
  local results = e.result

  assert(packet[1] == '')
  assert(packet[2] == const.network.master_header)
  assert(packet[3] == const.network.packet_header.packed_request)
  -- assert(packet[5] == null) -- Locale.compress changes index
  
  local nlstrings = Table.pop(Savedata.packets, assert(tonumber(packet[4])))
  if not nlstrings then
    log:debug('Recieved packed request with unknown index. Ignoring.')
    return
  else
    local i = 0
    for word in string_gmatch(results, '\0([^\0]*)') do
      i = i + 1
      dict:set_lstring_translation(nlstrings[i], word)
      end
    assert(i == #nlstrings, 'Incorrect packet length.')
    log:debugf('Pack.unpack unpacked %s requests', i)
    end
  end


return Packet