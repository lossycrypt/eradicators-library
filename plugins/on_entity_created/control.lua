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
-- local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
-- local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Constants                                                                  --
-- -------------------------------------------------------------------------- --
local script = EventManager .get_managed_script    'on_entity_created'

local on_entity_created = script.generate_event_name('on_entity_created')
local raise_event       = script.raise_event

-- -------------------------------------------------------------------------- --
-- Events                                                                     --
-- -------------------------------------------------------------------------- --

----------
-- All-in-one entity building event.
--
-- Combines the following events:  
-- @{FAPI events on_built_entity}  
-- @{FAPI events on_robot_built_entity}  
-- @{FAPI events script_raised_built}  
-- @{FAPI events script_raised_revive}  
-- @{FAPI events on_entity_cloned}  
-- @{FAPI events on_trigger_created_entity}  
--
-- @tfield LuaEntity created_entity The entity built.
-- @tfield[opt] NaturalNumber player_index
-- @tfield[opt] LuaEntity robot The robot that did the building.
-- @tfield[opt] LuaItemStack stack The item used to do the building.
-- @tfield[opt] LuaItemPrototype item The item prototype used to build the entity. Note this won't exist in some situations (built from blueprint, undo, etc).
-- @tfield[opt] Tags tags The tags associated with this entity.
-- @tfield[opt] LuaEntity clone_source The entity that this entity was cloned from.
-- @tfield[opt] LuaEntity trigger_source The entity with a trigger prototype (such as capsules) that created this entity.
--
-- @within ExtraEvents
-- @table on_entity_created

-- PLAYER / ROBOT
script.on_event({
  -- {created_entity=, player_index=, stack=, item[opt]=, tags[opt]=}
  defines.events.on_built_entity      ,
  -- {created_entity=, robot=, stack=, tags[opt]=}
  defines.events.on_robot_built_entity
  }, function(e)
  -- This is the most common event so it's best
  -- for performance if it can stay un-remapped.
  return raise_event(on_entity_created, e) end)

-- MOD SCRIPT
script.on_event({
  -- {entity=}
  defines.events.script_raised_built,
  -- {entity=, tags[opt]=}
  defines.events.script_raised_revive
  }, function(e)
  e.created_entity = e.entity
  e.entity         = nil
  return raise_event(on_entity_created, e) end)

-- CLONE
script.on_event({
  -- {source=, destination=}
  defines.events.on_entity_cloned,
  }, function(e)
  e.created_entity = e.destination
  e.destination    = nil
  e.clone_source   = e.source
  e.source         = nil
  return raise_event(on_entity_created, e) end)

-- TRIGGER
script.on_event({
  -- {entity=, source[opt]=}
  defines.events.on_trigger_created_entity,
  }, function(e)
  e.created_entity = e.entity
  e.entity         = nil
  e.trigger_source = e.source
  e.source         = nil
  return raise_event(on_entity_created, e) end)


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

