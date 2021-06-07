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

local log  = elreq('erlib/lua/Log'  )().Logger  'SimulationSFP'
-- local stop = elreq('erlib/lua/Error')().Stopper 'EventManager'

-- local Verificate = elreq('erlib/lua/Verificate')()
-- local Verify           , Verify_Or
--     = Verificate.verify, Verificate.verify_or

-- local Tool       = elreq('erlib/lua/Tool'      )()

local Table      = elreq('erlib/lua/Table'     )()
local Array      = elreq('erlib/lua/Array'     )()
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
return function (EventManager)


  -- ------------------------------------------------------------------------ --
  -- simulation_surface_force_player                                          --
  -- ------------------------------------------------------------------------ --

  -- Any mod *will* miss events in the following circumstances:
  -- 
  -- a) The event happend before the mod was added to the map.
  --
  -- b) The event happend during the on_init of another mod
  --    *on map creation* if the other mod is loaded before
  --    this mod. (Supposedly fixed for 0.17.44+?)
  --
  -- c) The event happend during the on_init of another mod
  --    *being added to an existing map*.
  --  
  
  -- Any PLUGIN will miss events:
  --
  -- a) A plugin is added at a later stage of development to an
  --    existing map, because simulation only works on a whole-mod
  --    level.
  --    Fixing this would require storing indexes and tech uids
  --    *for each plugin*, which would be too expensive.
  
  -- Approximate cost of storing indexes:
  --   
  --   Technology: Crc32 UID is ~2KB per 500 technologies.
  --
  --   Chunk: UID with 4byte/chunk would be ~4KB per km²
  
  -- ------------------------------------------------------------------------ --
  -- Simulation : surfaces, forces, players                                   --
  -- ------------------------------------------------------------------------ --

  ----------
  -- Enforces raising of easily missable events.
  -- 
  -- Because of certain quirks of the factorio engine a mod might not 
  -- recieve an event even if it has a handler for that event.
  --
  -- Specifically a mod will not recieve __any__ events before it's own
  -- on\_init handler has finished. Thus any events raised by __other mods__
  -- during their on\_init will be missed. I call this __overshadowing__.
  -- 
  -- Simulation aims to reduce edge cases and make event handlers more reliable.
  -- For this EventManager simulates __some__ of these
  -- overshadowed events when it detects them in it's own on_init. 
  --
  -- Namely EventManager detects the creation and deletition of surfaces,
  -- forces and players. And the researching and __un__researching of technologies.
  --
  -- All simulated events are raised with the additional event data
  -- `{simulated = true}` to make them distingusishable from natural events.
  --
  -- Simulation also happens when the mod is first added to a map. This means
  -- even __if your mod is added to an old map__ you will still recieve i.e.
  -- on\_player\_created for __all__ players that already exist in the map.
  -- Removing the need to manually detect which players, forces or surfaces
  -- already existed before.
  --
  -- __Known Issue:__ Simulated on\_forces\_merged events only contains `source_index`,
  -- but not `source_name` or `destination` because that information is lost for
  -- overshadowed force mergers.
  -- 
  -- 
  -- @within Concepts
  -- @table Simulation


  --[[

    on_force_created   -> force         :: LuaForce
    on_forces_merged   -> source_name   :: string
                          source_index  :: uint
                          destination   :: LuaForce

    on_surface_created -> surface_index :: uint
    on_surface_deleted -> surface_index :: uint

    on_player_created  -> player_index  :: uint
    on_player_removed  -> player_index  :: uint

  --]]

  local function CreateSimulation(
      created_event,   created_event_index_path,
    destroyed_event, destroyed_event_index_path,
    game_key,
    
    sim_create_event_key, sim_create_obj_value_path,
    sim_remove_event_key
    
    )

    local NAME_PREFIX = 'em-simulation:'..game_key
    local SAVEDATA_PATH = {'event_manager','simulation',game_key}

    local NewHandler = function(tbl)
      EventManager.new_handler(Table.smerge(tbl,{
        name_prefix = NAME_PREFIX,
        persistent  = true,
        }))
      end
    
    local Savedata
    local function remember_index (index)
      Array.insert_once(Savedata.known_indexes, index)
      end
    local function forget_index (index)
      Array.unsorted_remove_value(Savedata.known_indexes, index)
      end
    local function link_savedata()
      -- beware on_load before on_config
      Savedata = Table.get(global,SAVEDATA_PATH)
      end

    NewHandler{
      EventManager.event_uid.on_load,
      link_savedata
      }
      
    -- Store indexes on naturally occuring events.
    NewHandler {
      defines.events[created_event],
      filter = function(e) return not e.simulated end,
      function(e) remember_index(Table.get(e,created_event_index_path)) end
      }
    NewHandler {
      defines.events[destroyed_event],
      filter = function(e) return not e.simulated end,
      function(e) forget_index(Table.get(e,destroyed_event_index_path)) end
      }
      
    -- Simulate indexes when other mods might have overshadowed them.
    NewHandler {
      {EventManager.event_uid.on_init,EventManager.event_uid.on_config},
      function(e)
      
        -- create/read savedata
        Savedata = Table.sget(global,SAVEDATA_PATH,{})
        Table.sget(Savedata,{'known_indexes'},{});
        local known = Set.from_values(Savedata.known_indexes)
        
        -- missed object removal?
        for index in pairs(known) do
          if game.players[index] == nil then
            log:debug(
              '[tick ', e.tick, '] ',
              'Event simulated: ', destroyed_event, ' → Index: ', index
              )
            forget_index(index)
            local e = {simulated = true}
            Table.set(e, sim_remove_event_key, index)
            EventManager.raise_private(defines.events[destroyed_event], e)
            end
          end
        
        -- missed new object?
        for _,obj in pairs(Table.get(game,{game_key})) do
          if not known[obj.index] then
            log:debug(
              '[tick ', e.tick, '] ',
              'Event simulated: ', created_event,
              ' → Index: ', obj.index, ', Name: "', obj.name,'"'
              )
            remember_index(obj.index)
            local e = {simulated = true}
            Table.set(e, sim_create_event_key, 
              Table.get(obj, sim_create_obj_value_path)
              )
            EventManager.raise_private(defines.events[created_event], e)
            end
          end

        end
      }
    end
    

  -- Order is important! surface → force → player   

  CreateSimulation(
    'on_surface_created',{'surface_index'},
    'on_surface_deleted',{'surface_index'},
    'surfaces',
    {'surface_index'}, {'index'},
    {'surface_index'}
    )
   
  CreateSimulation(
    'on_force_created',{'force','index'},
    'on_forces_merged',{'source_index'},
    'forces',
    {'force'}, {}, -- empty path == object itself
    {'source_index'} -- is always index
    -- name and destination are unknown for overshadowed force removal!
    -- @future: Create a seperate event just for this?
    -- EventManager.event_uid.on_force_removed
    )

  CreateSimulation(
    'on_player_created',{'player_index'},
    'on_player_removed',{'player_index'},
    'players',
    {'player_index'}, {'index'},
    {'player_index'}
    )

  -- Legacy:
  --   Requires 0.17.46+ for game.forces[force.index]
    
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → event.simulation_surface_force_player') end
end

