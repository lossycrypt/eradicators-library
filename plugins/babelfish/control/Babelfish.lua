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
    log:debugf('Babelfish: raised on_babelfish_translation_state_changed (pindex %s). '
      , pindex)
    return script.raise_event(
      script.events.on_babelfish_translation_state_changed,
      {player_index = pindex}
      )
    end
    
  -- dict   -> raise for all players with that dict
  -- pindex -> raise for just one player
  Babelfish.raise_on_translation_state_changed = function(dict, pindex)
    if dict
    then 
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

-- on_nth_tick(20)
Babelfish.request_language_codes = function(e)
  local players = Savedata:get_lcode_requesters()
  assert(players, 'Failure to deactivate request_language_codes (no dirty lcodes).')

  for _, p in pairs(players) do
    log:debugf('Sent lcode request to "%s".', p.name)
    assert(p.request_translation(const.lstring.language_code))
    end
  end


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
  
  local is_first_window_tick = e.tick % window == 0
  
  if is_first_window_tick then
    local max_allowance = window * max
    local new_allowance = math.min(allowance + max_allowance, max_allowance)
    --
    if new_allowance == max_allowance
    then
      -- less or equal max_allowance, exact value
      log:debugf('Estimated bandwidth: %6.f kb/s'
        , -1 * (ups/window) * (allowance - max_allowance) / 1024)
    elseif new_allowance >= 0
    then
      -- in balance on average, precise value is unknown
      log:debugf('Estimated bandwidth: %6.f kb/s'
      , (ups/window) * max_allowance / 1024)
    else
      -- overtaxing, precise value unknown
      log:debugf('Estimated bandwidth: %6.f kb/s'
        , -1 * (ups/window) * (allowance - max_allowance) / 1024)
      end
    --
    allowance = Savedata:set_byte_allowance(new_allowance)
    end
  --
  -- Packed (once per window)
  if Babelfish.is_packaging_enabled()
  then
    if is_first_window_tick
    then
      if allowance < const.network.bytes.packet_median
      then
        log:debugf('Byte allowance     : %6.f bytes, NO PACKET SENT (packed).'
          , allowance)
      else
        local pack_count_this_tick
          = math.floor(allowance / const.network.bytes.packet_median)
        log:debugf('Byte allowance     : %6.f bytes, %3.f packets (packed).'
          ,allowance , pack_count_this_tick)
        Packet.send(p, dict, pack_count_this_tick)
        Savedata:substract_byte_allowance(allowance)
        end
      end
  --
  -- Raw (multiple per tick)
  else
    if allowance < const.network.bytes.packet_median
    then
      log:debugf('Byte allowance     : %6.f bytes, NO PACKET SENT.', allowance)
      return
    else
      local pack_count_this_tick
        = math.floor(max / const.network.bytes.packet_median)
      log:debugf('Byte allowance     : %6.f bytes, %3.f packets.'
        ,allowance , pack_count_this_tick)
      --
      -- Can not use for-loop due to possibile infinity of pack_count.
      local next = dict:iter_requests()
      local i = 0; repeat i = i + 1
        local request = next()
        if not request then return end
        p.request_translation(request[rindex.lstring])
        until i >= pack_count_this_tick
      end
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
    -- 
    -- Because Babelfish.update_handlers() can not manipulate
    -- global (due to on_load compatibility) this is the 
    -- final place to change Savedata before Babelfish shuts down.
    if not dict:has_requests()
    then
      Savedata:set_byte_allowance(nil)
      Savedata:purge_packets()
      Savedata:remove_unused_dictionaries()
      StatusIndicator.destroy_all()
      Babelfish.update_handlers()
      end
    end
    
  -- This is an estimate of the size of one "on_string_translated"
  -- event packet on the physical network.
  local function get_packet_size(e)
    local bytes = 0
      + 4 -- e.player_index (32-bit unsigned integer)
      + 4 -- e.name         (32-bit unsigned integer)
      + 4 -- e.tick         (32-bit unsigned integer)
      + 1 -- e.translated   (boolean, rounded up    )
      + #(e.result or '')
      + nlstring_size(e.localised_string)
    bytes = bytes
      + (math.ceil(bytes / const.network.bytes.mtu)
         * const.network.bytes.packet_overhead)
    log:sayf('Packet size        : %6.f bytes', bytes)
    return bytes end
    
  local function remember_packet_size(bytes)
    Savedata:substract_byte_allowance(bytes)
    end
  
  local cases = {}
  
  function cases.flib_packet(e)
    -- U+292C FALLING DIAGONAL CROSSING RISING DIAGONAL
    -- local flib_seperator = '⤬' -- '\u{292C}'
    log:debugf('FLIB packet ignored: %6.f bytes (≊%5.f kb/s).'
      , e.bytes
      , e.bytes * Local.ticks_per_second_float() / 1024)
    end
    
  function cases.babelfish_language_code(e)
    local pdata, p = Savedata:get_pdata(e)
    Savedata:set_pdata_lcode(e, nil, e.result)
    Babelfish.raise_on_translation_state_changed(nil, p.index)
    Babelfish.update_handlers()
    -- Try to start right now. (Fixes SP-Instant-Mode missing of first window.)
    if Babelfish.is_sp_instant_mode()
    then
      Savedata:set_byte_allowance(Babelfish.get_max_bytes_per_tick())
      Babelfish.request_translations{tick = 0}
      end
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
      if (len <= 1) or (lstring[1] ~= '')
      then
        return 'raw_packet'
      -- babelfish packets
      elseif lstring[2] == const.network.master_header
      then
        if lstring[3] == const.network.packet_header.packed_request
        then
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

do
  
  -- Todo: This would benefit from a re-settable AutoCache

  local is_sp_instant_mode, f5_clear = Memoize(function()
    return (not game.is_multiplayer())
       and Setting.get_value('map', const.setting_name.sp_instant_translation)
    end)

  local max_bytes_per_tick, f1_clear = Memoize(function()
    if is_sp_instant_mode[true] then
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
    if (not game.is_multiplayer()) and (not flag.IS_DEV_MODE)
    then
      return false
    else
      return Setting.get_value('map', const.setting_name.enable_packaging)
      end
    end)
    
  -- Because there is no event for game.speed changes
  -- this is also called via on_nth_tick(300).
  Babelfish.on_runtime_mod_setting_changed = function()
    f1_clear()
    f2_clear()
    f3_clear()
    f4_clear()
    f5_clear()
    end
  
  Babelfish.get_max_bytes_per_tick
    = function() return assert(max_bytes_per_tick[true]) end
    
  Babelfish.get_max_bytes_in_transit
    = function() return assert(max_bytes_in_transit[true]) end
    
  Babelfish.get_transit_window_ticks
    = function() return assert(transit_window_ticks[true]) end
      
  Babelfish.is_packaging_enabled
    = function() return is_packaging_enabled[true] end
    
  Babelfish.is_sp_instant_mode
    = function() return is_sp_instant_mode[true] end
    
    end
    
    
    
return Babelfish