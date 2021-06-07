-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description is ignored for submodules.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
--
-- @module EventManager

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --

-- local log  = elreq('erlib/lua/Log'  )().Logger  'EventManager'
-- local stop = elreq('erlib/lua/Error')().Stopper 'EventManager'

-- local Verificate = elreq('erlib/lua/Verificate')()
-- local Verify           , Verify_Or
--     = Verificate.verify, Verificate.verify_or

-- local Tool       = elreq('erlib/lua/Tool'      )()

-- local Table      = elreq('erlib/lua/Table'     )()
-- local Array      = elreq('erlib/lua/Array'     )()
-- local Set        = elreq('erlib/lua/Set'       )()



-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --
-- This file is required by EventManager itself,
-- thus loading of EventManager is not finished when
-- this file called and EventManager can not be
-- require()'ed, because that would create a circular
-- dependency.
--
-- This also ensures that the calling mod is the only
-- one require()'ing EventManager and thus avoids
-- different "path" strings causing package.loaded to
-- be unable to catch the subsequent require calls.
--
return function (EventManager, Private)


  -- ------------------------------------------------------------------------ --
  -- on_player_changed_chunk                                                  --
  -- ------------------------------------------------------------------------ --

  ----------
  -- Raised when the player moves or is teleported across a chunk border on
  -- the same surfaces or has moved to another surface.
  -- 
  -- Abstracts:  
  -- @{FAPI Events on_player_changed_position}  
  -- @{FAPI Events on_player_changed_surface}  
  -- 
  -- @tfield uint player_index
  -- @tfield uint|nil surface_index _If_ the player changed surfaces then this is
  -- the old surfaces index.
  -- @tfield ChunkPositionAndArea old_chunk
  -- @tfield ChunkPositionAndArea new_chunk
  --
  -- @within Built-in Meta-Events
  -- @table on_player_changed_chunk


  local event_uid   = EventManager.new_event(
    'on_player_changed_chunk',
    Private.new_private_event_uid() )
  
  
  -- Re-raises event with wrapper event_uid.
  local function raise_event (e)
    return Private.raise_private_wrapped_event(event_uid, e)
    end
    

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
  local function chunk_position_plus_area(cpos)
    local lt = {x = cpos.x*32   , y = cpos.y*32   }
    local rb = {x = cpos.x*32+32, y = cpos.y*32+32}
    cpos.area = {
      left_top     = lt, lt = lt,
      right_bottom = rb, rb = rb}
    return cpos
    end

 
  -- Compares two (chunk-) positions.
  local function is_position_equal(posA, posB)
    return (posA.x == posB.x) and (posA.y == posB.y)
    end
    
  local POSITION_ZERO = position_to_chunk_position{x=0,y=0}
    
  -- ------------------------------------------------------------------------ --
  -- Savedata                                                                 --
  -- ------------------------------------------------------------------------ --
  
  local SAVEDATA_PATH = {'event_manager','event_wrapper','on_player_changed_chunk'}
  local Savedata
    
    
  local function on_load()
    Savedata = Table.get(global, SAVEDATA_PATH, {})
    if Savedata.players then --on load before on config... fuck you
      setmetatable(Savedata.players,{
        -- auto-create player subtables
        __index = function(self,key) return Table.set(self,{key},{}) end
        })
      end
    end
    
    
  Private.new_event_wrapper(event_uid, {
      
    { EventManager.event_uid.on_load,
      on_load
      },
      
    {{EventManager.event_uid.on_init,
      EventManager.event_uid.on_config},
      function(e)
        Savedata = Table.sget(global, SAVEDATA_PATH, {})
        Table.sget(Savedata,{'players'},{})
        on_load()
        end
      },
    
    { defines.events.on_player_removed,
      function(e)
        Savedata.players[e.player_index] = nil
        end
      },
      
      
      
    -- ------------------------------------------------------------------------ --
    -- Wrapper                                                                  --
    -- ------------------------------------------------------------------------ --
    
    {
      --FAPI: "In the instance a player is moved off a surface due to it being deleted this is not called."
      defines.events.on_player_changed_surface,
      function(e,p)
        -- e.surface_index remains unchanged
        e.old_chunk = Savedata.players[e.player_index].old_chunk or POSITION_ZERO
        e.new_chunk = position_to_chunk_position(p.position)
        Savedata.players[e.player_index].old_chunk = e.new_chunk
        return raise_event(e)
        end
      },
      
    {
      defines.events.on_player_changed_position,
      function (e,p)
        local old_chunk = Savedata.players[e.player_index].old_chunk or POSITION_ZERO
        local new_chunk = position_to_chunk_position(p.position)
        if not is_position_equal(old_chunk, new_chunk) then
          Savedata.players[e.player_index].old_chunk = new_chunk
          e.old_chunk = chunk_position_plus_area(old_chunk)
          e.new_chunk = chunk_position_plus_area(new_chunk)
          return raise_event(e)
          end
        end
      },
    
  })


-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → event.on_player_changed_chunk') end
end

