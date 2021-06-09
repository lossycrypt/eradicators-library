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

local log  = elreq('erlib/lua/Log'  )().Logger  'SimulationTechnology'
-- local stop = elreq('erlib/lua/Error')().Stopper 'EventManager'

-- local Verificate = elreq('erlib/lua/Verificate')()
-- local Verify           , Verify_Or
--     = Verificate.verify, Verificate.verify_or

-- local Tool       = elreq('erlib/lua/Tool'      )()

local Table      = elreq('erlib/lua/Table'     )()
local Array      = elreq('erlib/lua/Array'     )()
-- local Set        = elreq('erlib/lua/Set'       )()

local Cache      = elreq('erlib/factorio/Cache')()
local Crc32      = elreq('erlib/lua/Coding/Crc32')()

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
  -- Template                                                                  --
  -- ------------------------------------------------------------------------ --

  -- -------
  -- Custom Event Description
  --
  -- @table Template
  
    
  -- ------------------------------------------------------------------------ --
  -- Simulation : technology                                                  --
  -- ------------------------------------------------------------------------ --

  -- Stores an array of Crc32(technology.name) for each force.
  -- Compares the array to actual research status in on_init, on_config
  -- and on_force_reset.

  --[[

    on_technology_effects_reset -> force :: LuaForce, Preserves research state of technologies.
    on_force_reset              -> force :: LuaForce
    on_research_finished        -> research :: LuaTechnology
                                -> by_script :: boolean
  --]]

  do

    local SAVEDATA_PATH = {'event_manager','simulation','technologies'}
    
    EventManager.new_event('on_research_reset')

    local NewHandler = function(tbl)
      EventManager.new_handler(Table.smerge(tbl,{
        name_prefix = 'em-simulation:technologies',
        persistent  = true,
        }))
      end
      
    -- Maps {uid -> name} and {name -> uid}.
    local _map = Cache.AutoCache(function(r)
      for _,t in pairs(game.technology_prototypes) do
        -- Storing all technology names for every force would
        -- waste too much space. So only the crc32 is stored.
        local uid = Crc32.encode(t.name)
        if r[uid] ~= nil then
          stop('Technology name crc32 collision!\n', uid, '\n', t.name)
          end
        r[t.name], r[uid] = uid, t.name -- double lookup
        end
      end)
      
    local Savedata
    
    -- get force researched_uids
    local function get_fuids(force)
      local x = Table.sget(Savedata,{force.index,'researched_uids'},{})
      return x
      end
    
    local function store_tech_uid(force,technology)
      Array.insert_once(get_fuids(force),_map[technology.name])
      end
      
    local function forget_tech_uid(force,technology)
      Array.unsorted_remove_value(get_fuids(force),_map[technology.name])
      end
    
    -- Compares the researched_uids of a force with the current technology
    -- state and if nessecary updates savedata and raises un/research events.
    local function check_force(e,force,simulated)
      -- remove uids if the technology no longer exists
      local researched_uids_array = Array(get_fuids(force))
      for i,uid in pairs(researched_uids_array) do
        if _map[uid] == nil then
          researched_uids_array:shuffle_pop(i)
          end
        end
      -- iter all technologies and compare with known state
      local researched_uids = Table.map( -- Set {name -> uid}
        get_fuids(force), function(v) return v,_map[v] end, {}
        )
      for _,tech in pairs(force.technologies) do
        -- missed research?
        if tech.researched and not researched_uids[tech.name] then
          log:debug(
            '[tick ', e.tick, '] ',
            'Event simulated: on_research_finished, ',
            ' → Force: ', force.name,
            ', Technology: ', tech.name
            )
          store_tech_uid(force,tech)
          EventManager.raise_private(
            defines.events.on_research_finished,
            {
              research  = tech ,
              by_script = false,
              -- source of research is unknown
              --
              -- @future: If the mod is added to the map for the first time
              -- it could be assumed that all old techs are not by_script, 
              -- and after that it could be assumed that all overshadowed
              -- events *are* by_script.
              --
              simulated = true, -- is tautologically always simulated
              }
            )
        -- missed un-research?
        elseif (not tech.researched) and (researched_uids[tech.name]) then
          forget_tech_uid(force,tech)
          EventManager.raise_private(
            EventManager.event_uid.on_research_reset,
            {research  = tech, simulated = not not simulated}
            )
          end
        end
      end

    -- Beware on_load before on_config.
    NewHandler{
      EventManager.event_uid.on_load,
      function() Savedata = Table.get(global,SAVEDATA_PATH) end
      }

    -- Remove savedata when forces are removed.
    -- Creation of new forces is handled implicitly by get_fuids().
    NewHandler {
      defines.events.on_forces_merged,
      function(e)
        Table.set(Savedata,{e.source_index},nil)
        if e.destination then check_force(e, e.destination, false) end
        end
      }

    -- Store indexes on naturally occuring events.
    NewHandler {
      defines.events.on_research_finished,
      filter = function(e) return not e.simulated end,
      function(e) store_tech_uid(e.research.force, e.research) end
      }
      
    -- Convert: "on_force_reset" -> "on_research_reset"
    NewHandler {
      defines.events.on_force_reset,
      function(e) check_force(e, e.force, false) end
      }

    -- Simulate un/research when other mods might have overshadowed it.
    NewHandler {
      {EventManager.event_uid.on_init,EventManager.event_uid.on_config},
      function(e)
        Savedata = Table.sget(global, SAVEDATA_PATH, {})
        for _,force in pairs(game.forces) do check_force(e, force, true) end
        end
      }
      
      
    end
  
  

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → event.Template') end
end

