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
    log:debug('Recieved packed request with unknown index.')
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