-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

--------------------------------------------------
-- Description is ignored for submodules.
--
-- @submodule EventManager

-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Locals / Init                                                              --
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
-- Api Documentation Summary                                                  --
-- -------------------------------------------------------------------------- --

--[[ on_built_entity

  Called when player builds something. Can be filtered using LuaPlayerBuiltEntityEventFilters

  Contains
  created_entity :: LuaEntity
  player_index :: uint
  stack :: LuaItemStack
  item :: LuaItemPrototype (optional): The item prototype used to build the entity. Note this won't exist in some situations (built from blueprint, undo, etc).
  tags :: Tags (optional): The tags associated with this entity if any.
--]]

--[[ on_robot_built_entity

  Called when a construction robot builds an entity. Can be filtered using LuaRobotBuiltEntityEventFilters

  Contains
  created_entity :: LuaEntity: The entity built.
  robot :: LuaEntity: The robot that did the building.
  stack :: LuaItemStack: The item used to do the building.
  tags :: Tags (optional): The tags associated with this entity if any.
--]]

--[[ script_raised_built

  A static event mods can use to tell other mods they built something with a script. This event is only raised if a mod uses it with script.raise_event() or when 'raise_built' is passed to LuaSurface::create_entity. Can be filtered using LuaScriptRaisedBuiltEventFilters
  Contains
  entity :: LuaEntity
--]]

--[[ script_raised_revive

  A static event mods can use to tell other mods they revived something with a script. This event is only raised if a mod uses it with script.raise_event() or when 'raise_revive' is passed to LuaEntity::revive. Can be filtered using LuaScriptRaisedReviveEventFilters

  Contains
  entity :: LuaEntity
  tags :: Tags (optional): The tags associated with this entity if any.
--]]

--[[ on_entity_cloned

  Called when an entity is cloned. Can be filtered for the source entity using LuaEntityClonedEventFilters

  Contains
  source :: LuaEntity
  destination :: LuaEntity
--]]

--[[ on_trigger_created_entity

  Called when an entity with a trigger prototype (such as capsules) create an entity AND that trigger prototype defined trigger_created_entity="true".

  Contains
  entity :: LuaEntity
  source :: LuaEntity (optional)
--]]


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


  ----------
  -- Combines all entity building related events into one.
  --
  -- @{FAPI Events on_built_entity}  
  -- @{FAPI Events on_robot_built_entity}  
  -- @{FAPI Events script_raised_built}  
  -- @{FAPI Events script_raised_revive}  
  -- @{FAPI Events on_entity_cloned}  
  -- @{FAPI Events on_trigger_created_entity}  
  --
  --
  -- @tfield LuaEntity created_entity The entity built.
  -- @tfield[opt] LuaEntity robot The robot that did the building.
  -- @tfield[opt] LuaPlayer player The player who did the building. 
  -- @tfield[opt] uint player_index
  -- @tfield[opt] LuaItemStack stack The item used to do the building.
  -- @tfield[opt] LuaItemPrototype item The item prototype used to build the entity. Note this won't exist in some situations (built from blueprint, undo, etc).
  -- @tfield[opt] Tags tags The tags associated with this entity.
  -- @tfield[opt] LuaEntity clone_source The entity that this entity was cloned from.
  -- @tfield[opt] LuaEntity trigger_source The entity with a trigger prototype (such as capsules) that created this entity.
  --
  -- @table on_entity_created
  
  local EVENT_UID = LuaBootstrap.generate_event_name()
  
  
  local function raise_event(e)
    --??
    
    e.name = EVENT_UID -- leaving the original id is faster and more versatile?
    
    -- EventManager.raise_private(EVENT_UID,e,p)
    
    return Private.on_every_event(e) -- Allow direct access for speed?
    end
  
  local function event_remapper (mappings)
    local remapper = Table.remapper(mappings)
    return function(e) return raise_event(remapper(e)) end
    end


  -- Conditionally create these handlers
  -- only *if* at least one handler has been registered to the event.
  Private.new_event_wrapper{
    
    -- event name
    'on_normalized_built_entity',
    
    -- event id?
    EVENT_UID,
    
    
    -- arbitary number of new_handler() argument tables
    
-- PLAYER / ROBOT
    { -- created_entity, player_index, stack, item[opt], tags[opt]
      {defines.events.on_built_entity      ,
      -- created_entity, robot, stack, tags[opt]
      defines.events.on_robot_built_entity },
      -- This is the most common event so it's best
      -- for performance if it can stay un-remapped.
      raise_event
      },

-- SCRIPT
    { -- entity
      {defines.events.script_raised_built,
      -- entity, tags[opt]
      defines.events.script_raised_revive},
      event_remapper { entity = 'created_entity' }
      },

-- CLONE
    { -- source, destination
      defines.events.on_entity_cloned,
      event_remapper { destination = 'created_entity', source = 'clone_source'}
      },

-- TRIGGER
    { -- entity, source[opt]
      defines.events.on_trigger_created_entity,
      event_remapper { entity = 'created_entity', source = 'trigger_source'}
      },

    }

  -- ------------------------------------------------------------------------ --
  -- on_entity_created                                                        --
  -- ------------------------------------------------------------------------ --


  

-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → event.on_entity_created') end
end

