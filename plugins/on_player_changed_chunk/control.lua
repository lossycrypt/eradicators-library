-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- Description is ignored for submodules.
--
-- @module EventManagerLite

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
local Table       = elreq('erlib/lua/Table'        )()

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local script = EventManager .get_managed_script    'on_player_changed_chunk'

local const = {
  on_player_changed_chunk =
    script.generate_event_name 'on_player_changed_chunk'
  }

-- -------------------------------------------------------------------------- --
-- Local Library                                                              --
-- -------------------------------------------------------------------------- --

-- Converts player position to chunk position
local math_floor = math.floor
local function position_to_chunk_position(position)
  return {
    x = math_floor(position.x/32),
    y = math_floor(position.y/32)
    }
  end

-- Adds area to ChunkPosition
-- @tparam ChunkPosition cpos
-- @treturn ChunkPositionAndArea
local function add_chunk_area(cpos)
  local lt = {x = cpos.x*32   , y = cpos.y*32   }
  local rb = {x = cpos.x*32+32, y = cpos.y*32+32}
  cpos.area = {
    left_top     = lt, lt = lt,
    right_bottom = rb, rb = rb}
  return cpos end
  
local function get_player_chunk_position_and_area(p)
  return add_chunk_area(position_to_chunk_position(p.position)) end

-- Compares two (chunk-)positions.
local function is_position_equal(posA, posB)
  return (posA.x == posB.x) and (posA.y == posB.y) end

-- -------------------------------------------------------------------------- --
-- Savedata                                                                   --
-- -------------------------------------------------------------------------- --
local Savedata
local SavedataDefaults = {players = {}}
PluginManager.manage_savedata  ('on_player_changed_chunk', function(_) Savedata = _ end, SavedataDefaults)
PluginManager.manage_garbage   ('on_player_changed_chunk')
PluginManager.classify_savedata('on_player_changed_chunk', {

  init_pdata = function(self, pindex)
    local p = game.players[assert(pindex)]
    return Table.set(self.players, {pindex}, {
      p = p,
      old_chunk = get_player_chunk_position_and_area(p)
      })
    end,

  sget_pdata = function(self, e, pindex)
    local pdata = self.players[pindex or e.player_index]
            or self:init_pdata(pindex or e.player_index)
    return pdata, pdata.p end,

  })
  
-- -------------------------------------------------------------------------- --
-- Events                                                                     --
-- -------------------------------------------------------------------------- --

local function on_player_changed_chunk(pdata, p, e)
  -- e.surface_index remains unchanged!
  e.old_chunk = pdata.old_chunk
  e.new_chunk = get_player_chunk_position_and_area(p)
  pdata.old_chunk = e.new_chunk
  return script.raise_event(const.on_player_changed_chunk, e) end

script.on_event(
  -- FAPI: "In the instance a player is moved off a surface due to
  -- it being deleted this is not called."
  defines.events.on_player_changed_surface,
  function(e)
    local pdata, p = Savedata:sget_pdata(e)
    return on_player_changed_chunk(pdata, p, e) end)

script.on_event(
  defines.events.on_surface_deleted,
  function(e)
    -- Checking which players are actually affected would need
    -- more Savedata. But it's not worth it to get a super-rare
    -- event 1% more exact.
    for pindex in pairs(game.players) do
      e.player_index = pindex
      local pdata, p = Savedata:sget_pdata(e)
      on_player_changed_chunk(pdata, p, Table.scopy(e))
      end
    end)
  
script.on_event(
  defines.events.on_player_changed_position,
  function (e)
    local pdata, p = Savedata:sget_pdata(e)
    if not is_position_equal(
      pdata.old_chunk,
      position_to_chunk_position(p.position)
      )
    then
      return on_player_changed_chunk(pdata, p, e)
      end
    end)

    
-- -------------------------------------------------------------------------- --
-- Documentation                                                              --
-- -------------------------------------------------------------------------- --

----------
-- Raised when the player moves or is teleported across a chunk border on
-- the same surface, or has moved to another surface. After a surface
-- was deleted this is called for all players regardless of if they were
-- actually on that surface.
-- 
-- Abstracts:  
-- @{FAPI events on_player_changed_position}  
-- @{FAPI events on_player_changed_surface}  
-- 
-- @tfield uint player_index
-- @tfield uint|nil surface_index _If_ the player changed surfaces then this is
-- the _old_ surfaces index.
-- @tfield ChunkPositionAndArea old_chunk
-- @tfield ChunkPositionAndArea new_chunk
--
-- @within ExtraEvents
-- @table on_player_changed_chunk