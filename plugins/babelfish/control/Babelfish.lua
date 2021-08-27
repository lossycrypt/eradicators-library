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
local log         = elreq('erlib/lua/Log'          )().Logger  'babelfish'
local stop        = elreq('erlib/lua/Error'        )().Stopper 'babelfish'
local assertify   = elreq('erlib/lua/Error'        )().Asserter(stop)

-- local Verificate  = elreq('erlib/lua/Verificate'   )()
-- local verify      = Verificate.verify
-- local isType      = Verificate.isType

local Math        = elreq('erlib/lua/Math'           )()
local Table       = elreq('erlib/lua/Table'          )()
-- local String      = elreq('erlib/lua/String'         )()
local Memoize     = elreq('erlib/lua/Meta/Memoize'   )()
local SwitchCase  = elreq('erlib/lua/Meta/SwitchCase')()

-- local ntuples     = elreq('erlib/lua/Iter/ntuples' )()

local Setting     = elreq('erlib/factorio/Setting' )()
local Locale      = elreq('erlib/factorio/Locale'  )()

local string_find
    = string.find

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local script = EventManager .get_managed_script    'babelfish'
local import = PluginManager.make_relative_require 'babelfish'
local const  = import '/const'

local rindex = const.index.request

local Local            = import '/locallib'
-- local Dictionary       = import '/control/Dictionary'
local RawEntries       = import '/control/RawEntries'
local StatusIndicator  = import '/control/StatusIndicator'
local Packet           = import '/control/Packet'

-- local Lstring          = import '/control/Lstring'
-- local lstring_is_equal = Lstring.is_equal
-- local lstring_ident    = Lstring.ident
-- local nlstring_is_equal = Locale.nlstring_is_equal
local nlstring_ident    = Locale.nlstring_to_string
local nlstring_size     = Locale.nlstring_size

-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
local Babelfish = {}

-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- Savedata                                                                   --
-- -------------------------------------------------------------------------- --
local Savedata
PluginManager.manage_savedata  ('babelfish', function(_) Savedata = _ end)

-- -------------------------------------------------------------------------- --
-- Event Raiser                                                               --
-- -------------------------------------------------------------------------- --
  
--------------------------------------------------------------------------------
-- Events.  
-- @section
--------------------------------------------------------------------------------

----------
-- Called when SearchType availability changes.
-- SearchTypes can become available or unavailable.
-- 
-- Mods that want to dynamically adjust their gui or similar must
-- call @{Babelfish.can_translate|can_translate} during this event to
-- get the new state. Other mods can safely ignore this event.
-- 
-- Use @{remotes.events} or @{EventManagerLite.events} to get
-- the event id.
-- 
-- See also: @{FAPI Data-Lifecycle|Data-Lifecycle "4. control init"}.
-- 
-- @tfield NaturalNumber player_index
-- @table on_babelfish_translation_state_changed
do end

do
  -- Keep it simple! can_translate() already includes all important logic.
  -- Not including extra event data encourages mod authors
  -- to use only one function for all updates instead of
  -- writing a special event-data parser.
  local _raise = function(pindex)
    log:debug('Babelfish: raised on_babelfish_translation_state_changed: ', pindex)
    return script.raise_event(
      script.events.on_babelfish_translation_state_changed,
      {player_index = pindex}
      )
    end
    
  -- dict   -> raise for all players with that dict
  -- pindex -> raise for just one player
  Babelfish.raise_on_translation_state_changed = function(dict, pindex)
    if dict then 
      for pindex, pdata in pairs(Savedata.players) do
        if pdata.dict == dict then _raise(pindex) end
        end
    else
      _raise(assert(pindex))
      end
    end
    
  end
  

-- -------------------------------------------------------------------------- --
-- Class Tick Handlers                                                        --
-- -------------------------------------------------------------------------- --

-- on_nth_tick(30)
Babelfish.request_language_codes = function(e)
  local players = Savedata:get_lcode_requesters()
  assert(players, 'Failure to deactivate request_language_codes (no dirty lcodes).')

  for _, p in pairs(players) do
    assert(p.request_translation(const.lstring.language_code))
    end
  end
  
-- V5
-- on_nth_tick(1)
-- Babelfish.request_translations = function(e)
-- 
--   -- Try to hide lag-spike in load screen by pre-emptive compilation.
--   RawEntries.precompile()
-- 
--   local dict, p = Savedata:get_active_dict()
--   assert(dict, 'Failure to deactivate request_translations (no active dict)')
--   
--   -- Remove too-large request from last tick from this ticks allowance.
--   -- This compensates requests from other mods and too large packet estimates.
--   local max  = Babelfish.get_max_bytes_per_tick()
--   local last = Savedata:pop_bytes_recieved_last_tick()
--   -- local bytes_allowed_this_tick = math.min(0, max + math.max(0, (max - last)))
--   -- local bytes_allowed_this_tick = math.min(0, max + Math.limit(-max, max - last, max))
--   local bytes_allowed_this_tick = Math.limit(0, 1.5 * max - last, 1.5 * max)
--   local pack_count_this_tick = 
--     math.floor(bytes_allowed_this_tick / const.network.bytes.packet_median)
--   
--   -- Log current bandwidth usage
--   if flag.IS_DEV_MODE then
--     -- if pack_count_this_tick == 0 then
--       -- log:debug('Bandwidth overuse, sending no packets this tick.', )
--     -- else
--       log:debugf('Tick allowance %7.f bytes, %3.f packets.'
--         ,max - last, pack_count_this_tick)
--       -- end
--     Table['+='](Savedata, {'bytes_last_second'}, last)
--     if e.tick % Local.ticks_per_second_int() == 0 then
--       log:debug(('Estimated bandwidth: %5.fkb/s')
--         :format(Savedata.bytes_last_second / 1024))
--       Savedata.bytes_last_second = nil
--       end
--     end
--     
--   local requests = RawEntries.requests
--   
--   local next = dict:iter_request_uids_loop(e.tick)
--   local i = 0; repeat i = i + 1
--     local uid = next()
--     if uid then
--       -- log:debug('Sent translation request for uid: ', uid)
--       p.request_translation(requests[uid][rindex.lstring])
--     else
--       break end
--     until i >= pack_count_this_tick
-- 
--   -- log:info('Player "', p.name, '" is timing out.')
--   end 

-- V6
-- on_nth_tick(1)
Babelfish.request_translations = function(e)

  -- Try to hide lag-spike in load screen by pre-emptive compilation.
  RawEntries.precompile()

  local dict, p = Savedata:get_active_dict()
  assert(dict, 'Failure to deactivate request_translations (no active dict)')
  
  local ups       = Local.ticks_per_second_float()
  local max       = Babelfish.get_max_bytes_per_tick()
  local window    = Babelfish.get_transit_window_ticks()
  local allowance = Savedata:get_byte_allowance()
  
  if e.tick % window == 0 then
    local new_allowance = window * max
    log:debugf('Estimated bandwidth: %5.fkb/s'
      , -1 * (ups/window) * (allowance - new_allowance) / 1024)
    allowance = new_allowance
    Savedata:set_byte_allowance(allowance)
  elseif 0 >= allowance then
    log:debugf('Byte allowance %7.f bytes, NO PACKET SENT.', allowance)
    return end
    
  local pack_count_this_tick = math.floor(max / const.network.bytes.packet_median)
  
  log:debugf('Byte allowance %7.f bytes, %3.f packets.'
    ,allowance , pack_count_this_tick)
    
  local requests = RawEntries.requests
  
  if Babelfish.is_packaging_enabled() then
    -- multi-tick-packet might simply not be feasible considering
    -- laggy connections
    Packet.send(p, dict, math.floor(allowance / const.network.bytes.packet_median) )
    -- Packet.send(p, dict, pack_count_this_tick * const.network.ticks_per_packet)
  else
    local next = dict:iter_request_uids_loop(e.tick)
    local i = 0; repeat i = i + 1
      local uid = next()
      if uid then
        p.request_translation(requests[uid][rindex.lstring])
      else
        break end
      until i >= pack_count_this_tick
      
    end

  end 

-- -------------------------------------------------------------------------- --
-- Class Event Handlers                                                       --
-- -------------------------------------------------------------------------- --

Babelfish.on_player_language_changed = function(e)
  Savedata:set_pdata_lcode_dirty(e, nil, true)
  Babelfish.update_handlers()
  end

  
-- -------------------------------------------------------------------------- --
  
do
  
  local function try_finalize_dictionary(dict)
    -- If no other dictionary are open this shuts down
    -- all Babelfish handlers, ending the translation cycle.
    if not dict:has_requests() then
      Savedata:set_byte_allowance(nil)
      Savedata:purge_packets()
      StatusIndicator.destroy_all()
      Babelfish.update_handlers()
      end
    end
    
  -- This is an estimate of the size of one "on_string_translated"
  -- event packet on the physical network.
  local function get_packet_size(e)
    local bytes = 0
      + 4 -- e.player_index (32-bit unsigned integer)
      + 1 -- e.translated   (boolean, rounded up    )
      + #(e.result or '')
      + nlstring_size(e.localised_string)
    bytes = bytes
      + (math.ceil(bytes / const.network.bytes.mtu)
         * const.network.bytes.packet_overhead)
    return bytes end
    
  local function remember_packet_size(bytes)
    Savedata:substract_byte_allowance(bytes)
    end
  
  local cases = {}
  
  function cases.flib_packet(e)
    -- U+292C FALLING DIAGONAL CROSSING RISING DIAGONAL
    -- local flib_seperator = '⤬' -- '\u{292C}'
    log:debugf('Ignoring flib packet (%5.f kb/s).'
      , e.bytes * Local.ticks_per_second_float() / 1024)
    end
    
  function cases.babelfish_language_code(e)
    local pdata, p = Savedata:get_pdata(e)
    Savedata:set_pdata_lcode(e, nil, e.result)
    Babelfish.raise_on_translation_state_changed(nil, p.index)
    Babelfish.update_handlers()
    end
    
  function cases.babelfish_packed_request(e)
    Packet.unpack(e.dict, e)
    try_finalize_dictionary(e.dict)
    end
    
  function cases.raw_packet(e)
    local dict    = assert(e.dict)
    local lstring = e.localised_string
    --
    dict:set_lstring_translation(lstring, e.result)
    try_finalize_dictionary(dict)
    end

  -- Test if Locale methods produce serpent-identical results.
  local test_nlstring_library = (not flag.DO_TESTS) and ercfg.SKIP or function(e)
    local lstring = e.localised_string
    local opt = {compact = true}
    local s_line = serpent.line(lstring, opt)
    local l_line = Locale.nlstring_to_string(lstring)
    local s_size = #serpent.line(lstring, opt)
    local l_size = Locale.nlstring_size(lstring)
    -- game.write_file('babelfish-nlstring-test.txt', '\ns_line: '.. s_line, true)
    -- game.write_file('babelfish-nlstring-test.txt', '\nl_line: '.. l_line, true)
    -- game.write_file('babelfish-nlstring-test.txt', '\ns_size: '.. s_size, true)
    -- game.write_file('babelfish-nlstring-test.txt', '\nl_size: '.. l_size, true)
    assertify(s_line == l_line, 'Unequal serialization.')
    assertify( -- Each "\n" in nlstring skews l_size by -1.
      (s_size == l_size)
      or ( (s_size > l_size) and (s_size <= 2+l_size) )
      , 'Unequal size: ', s_size, ' ~= ', l_size) 
    assertify(Locale.nlstring_is_equal(Locale.normalise(lstring), lstring) , 'Unequal normalise')
    end

  local analyzer = function(e)
    e.dict = Savedata:get_pdata(e).dict
    e.bytes = get_packet_size(e)
    remember_packet_size(e.bytes)
    test_nlstring_library(e)
    --
    local lstring = e.localised_string
    local len     = #lstring
    --
    if flag.DO_TESTS then test_nlstring_library(e) end
    --
    if (len == 1) then
      -- babelfish language code
      if (lstring[1] == const.lstring.language_code[1]) then
        return 'babelfish_language_code' end
      end
    --
    if e.dict then
      if (len <= 1) or (lstring[1] ~= '') then
        return 'raw_packet'
      -- babelfish packets
      elseif lstring[2] == const.network.master_header then
        if lstring[3] == const.network.packet_header.packed_request then
          return 'babelfish_packed_request' end
      -- flib packets
      elseif type(lstring[2]) == 'string'
        and string_find(lstring[2], '^FLIB')
        then
          return 'flib_packet'          
      -- unidentified packets
      else
        return 'raw_packet'
        end
      end
    end
  
  Babelfish.on_string_translated = SwitchCase(analyzer, cases)
  end
  
-- -------------------------------------------------------------------------- --

  

-- Babelfish.on_runtime_mod_setting_changed = function()
--     local ticks_per_second = 60 * game.speed
--     --
--     if (not game.is_multiplayer())
--     and Setting.get_value('map', const.setting_name.sp_instant_translation)
--     then
--       Savedata.max_bytes_per_tick
--         = math.huge
--     else
--       Savedata.max_bytes_per_tick
--         = (1024 * Setting.get_value('map', const.setting_name.network_rate))
--         / ticks_per_second
--       end
--     Savedata.max_bytes_in_transit
--       = (const.network.transit_window * ticks_per_second)
--       * Savedata.max_bytes_per_tick
--     --
--     log:debug('Updated settings max_bytes_per_tick: ', Savedata.max_bytes_per_tick)
--     log:debug('Updated settings max_bytes_in_transit: ', Savedata.max_bytes_in_transit)
--     end

do

  -- max_bytes_per_tick
  local max_bytes_per_tick, f1_clear = Memoize(function()
    if (not game.is_multiplayer())
    and Setting.get_value('map', const.setting_name.sp_instant_translation)
    then
      return math.huge
    else
      return (1024 * Setting.get_value('map', const.setting_name.network_rate))
             / Local.ticks_per_second_float()
      end
    end)
    
  local max_bytes_in_transit, f2_clear = Memoize(function()
    return (const.network.transit_window * Local.ticks_per_second_float())
           * max_bytes_per_tick
    end)
    
  local transit_window_ticks, f3_clear = Memoize(function() -- integer
    return math.floor(const.network.transit_window * Local.ticks_per_second_float())
    end)
    
  local is_packaging_enabled, f4_clear = Memoize(function()
    return 
     (not game.is_multiplayer())
      and Setting.get_value('map', const.setting_name.sp_instant_translation)
       or Setting.get_value('map', const.setting_name.enable_packaging)
    end)
    
  Babelfish.on_runtime_mod_setting_changed = function()
    f1_clear()
    f2_clear()
    f3_clear()
    f4_clear()
    end
  
  Babelfish.get_max_bytes_per_tick
    = function() return assert(max_bytes_per_tick[true]) end
    
  Babelfish.get_max_bytes_in_transit
    = function() return assert(max_bytes_in_transit[true]) end
    
  Babelfish.get_transit_window_ticks
    = function() return assert(transit_window_ticks[true]) end
      
  Babelfish.is_packaging_enabled
    = function() return assert(is_packaging_enabled[true]) end
    
    end
    
    
    
return Babelfish