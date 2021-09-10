-- (c) eradicator a.k.a lossycrypt, 2017-2021, not seperately licensable

--------------------------------------------------
-- LuaPlayer methods.
--
-- @{Introduction.DevelopmentStatus|Module Status}: Work in progress.
-- @{Introduction.Compatibility|Compatibility}: Factorio Runtime.
--
--
-- @module Player
-- @usage
--  local Player = require('__eradicators-library__/erlib/factorio/Player')()
  
-- -------------------------------------------------------------------------- --
-- Built-In                                                                   --
-- -------------------------------------------------------------------------- --
local elroot = (pcall(require,'erlib/empty')) and '' or '__eradicators-library__/'
local say,warn,err,elreq,flag,ercfg=table.unpack(require(elroot..'erlib/shared'))

-- -------------------------------------------------------------------------- --
-- Eradicators Library                                                        --
-- (Factorio does not allow runtime require!)                                 --
-- -------------------------------------------------------------------------- --
local log         = elreq('erlib/lua/Log'         )().Logger  'Player'
local stop        = elreq('erlib/lua/Error'       )().Stopper 'Player'
local assertify   = elreq('erlib/lua/Error'       )().Asserter(stop)

local Verificate  = elreq('erlib/lua/Verificate'   )()
local verify      = Verificate.verify


-- local Tool       = elreq('erlib/lua/Tool'      )()
    
local Table      = elreq('erlib/lua/Table'     )()
-- local Array      = elreq('erlib/lua/Array'     )()
-- local Set        = elreq('erlib/lua/Set'       )()

-- local Compose    = elreq('erlib/lua/Meta/Compose')()
-- local L          = elreq('erlib/lua/Lambda'    )()

local Memoize = elreq('erlib/lua/Meta/Memoize')()

local ntuples     = elreq('erlib/lua/Iter/ntuples' )()


-- -------------------------------------------------------------------------- --
-- Module                                                                     --
-- -------------------------------------------------------------------------- --

local Player,_Player,_uLocale = {},{},{}

-- -------
-- Nothing.
-- @within Todo
-- @field todo1

--------------------------------------------------------------------------------
-- Methods.
-- @section
--------------------------------------------------------------------------------

----------
-- Calls @{FOBJ LuaControl.can_reach_entity} and automatically
-- creates a local flying text at the entity position if not.
--
-- @tparam LuaPlayer p
-- @tparam LuaEntity entity
-- @tparam LocalisedString text (_default:_ `{"cant-reach"}`)
--
-- @treturn boolean 
function Player.try_reach_entity(p, entity, text)
  return p.can_reach_entity(entity)
      or (Player.notify(p, text or {'cant-reach'}, entity.position) and false)
  end

  
----------
-- Creates a plain localized flying text for a player.
--
-- Syntactic Sugar for @{FOBJ LuaPlayer create_local_flying_text}
--
-- @tparam LuaPlayer p
-- @tparam LocalisedString text
-- @tparam[opt=at the cursor position] Position position
--
function Player.notify(p, text, position)
  -- DOC: "if create_at_cursor is true all values except 'text' are ignored."
  return p.create_local_flying_text {
    text             = text        ,
    create_at_cursor = not position,
    position         = position    ,
    }
  end


do
  local players = {}
  
  local function from_key(key)
    local p = players[key]
    if (p and p.valid) then return p end
    return Table.set(players, {key}, game.get_player(key)) end
  
  ----------
  -- Gets a LuaPlayer object.
  --
  -- Functionally equivalent to @{FOBJ LuaGameScript.get_player},
  -- but faster because the player object is cached on the lua side.
  --
  -- @tparam NaturalNumber|string player A @{FOBJ LuaPlayer.index} or @{FOBJ LuaPlayer.name}
  -- @treturn LuaPlayer
  -- @function Player.get_player
  Player.get_player = from_key

  ----------
  -- Gets a LuaPlayer object.
  --
  -- Shortcut for  `Player.get_player(e.player_index)`.
  --
  -- @usage
  --   -- Maximum speed access to lua player objects.
  --   local getp = Player.get_event_player
  --   script.on_event(defines.events.on_something_happend, function(e)
  --     local p = getp(e)
  --     game.print(p.name .. ' did something!')
  --     end)
  --
  -- @tparam table e Any event table that contains `player_index`.
  -- @treturn LuaPlayer
  -- @function Player.get_event_player
  function Player.get_event_player(e) return from_key(e.player_index) end
    
  end
  
  
----------
-- Gets the item in the players cursor.
--
-- @tparam[opt] LuaPlayer p 
-- @tparam[opt] table e If you don't have a LuaPlayer object you can
-- instead pass an event table containing `player_index`.
--
-- @treturn nil|LuaItemStack Returns nil if the cursor was not
-- @{FOBJ LuaItemStack.valid_for_read}.
-- @treturn LuaPlayer
--
-- @function Player.get_valid_for_read_cursor_stack
do local _msg = 'No player index given.'
function Player.get_valid_for_read_cursor_stack(p, e)
  local p  = p or Player.get_event_player(e)
  local cs = p.cursor_stack
  if cs and cs.valid and cs.valid_for_read then
    return cs, p
  else
    return nil, p
    end
  end
  end
  
----------
-- Sets a shortcut to the opposite state it is in now.
--
-- @tparam LuaPlayer p
-- @tparam string name @{FOBJ LuaShortcutPrototype.name}
--
-- @treturn boolean The new state.
--
function Player.toggle_shortcut (p, name)
  local state = not p.is_shortcut_toggled(name)
  p.set_shortcut_toggled(name,state)
  return state end

--------------------------------------------------------------------------------
-- Draft.
-- @section
--------------------------------------------------------------------------------

  
----------
-- Gets the currently selected entity.
--
-- While holding a blueprint entity selection is not updated naturally
-- and @{FOBJ LuaControl.update_selected_entity} does not work. In that case
-- a best-guess result using @{FOBJ LuaSurface.find_entities_filtered}
-- is returned.
--
-- __Note:__ Emulation does _not_ check for entity visibility
-- (`force_visibility`, `render_to_forces`, etc). Emulation 
-- is based on `collision_box` instead of `selection_box`.
--
-- __Related MIR:__
-- [Method to get "selected" entity while player is holding a blueprint.](https://forums.factorio.com/viewtopic.php?f=28&t=99478)
--
-- @tparam LuaPlayer p
-- @tparam Position position
--
-- @treturn nil|LuaEntity
-- @function Player.get_selected_entity
do
  local priorities = Memoize(function(name)
    return game.entity_prototypes[name].selection_priority end)
  --
  function Player.get_selected_entity(p, position)
    if p.is_cursor_blueprint() and assert(position) then
      -- @future: Check size difference of selection_box and collision_box. 
      -- @future: prototype.force_visibility is not available at runtime?
      local selected
      local next, tbl, key = pairs(
        p.surface.find_entities_filtered{position = position}
        )
      key, selected = next(tbl, key)
      for _, entity in next, tbl, key do
        local a, b = priorities[entity.name], priorities[selected.name]
        if (a > b) or ((a == b) and (entity.position.y > selected.position.y)) then
          selected = entity
          end
        end
      return selected
      end
    return p.selected end
  end
  
-- -------------------------------------------------------------------------- --

do


  local _copyable_character_properties = {
    -- some of these will always be nil for characters
    'active'                                       ,
    'allow_dispatching_robots'                     ,
    -- 'auto_trash_filters'                           , -- does not preserve layout
    'bonus_mining_progress'                        ,
    'character_additional_mining_categories'       ,
    'character_build_distance_bonus'               ,
    'character_crafting_speed_modifier'            ,
    'character_health_bonus'                       ,
    'character_inventory_slots_bonus'              ,
    'character_item_drop_distance_bonus'           ,
    'character_item_pickup_distance_bonus'         ,
    -- 'character_logistic_slot_count'                ,
    'character_loot_pickup_distance_bonus'         ,
    'character_maximum_following_robot_count_bonus',
    'character_mining_speed_modifier'              ,
    'character_personal_logistic_requests_enabled' ,
    'character_reach_distance_bonus'               ,
    'character_resource_reach_distance_bonus'      ,
    'character_running_speed_modifier'             ,
    'character_trash_slot_count_bonus'             ,
    -- 'cheat_mode'                                   , -- not on disassociated characters
    'color'                                        ,
    'cursor_ghost'                                 ,
    'destructible'                                 ,
    'direction'                                    ,
    'driving'                                      ,
    'drop_target'                                  ,
    'energy'                                       ,
    'fluidbox'                                     ,
    'force'                                        ,
    'health'                                       ,
    'last_user'                                    ,
    'minable'                                      ,
    'mining_progress'                              ,
    'mining_state'                                 ,
    -- 'opened'                                       , -- doesn't work?
    'operable'                                     ,
    'orientation'                                  ,
    'picking_state'                                ,
    'render_player'                                ,
    'render_to_forces'                             ,
    'repair_state'                                 ,
    -- 'request_from_buffers'                         , -- only with personal logistics research
    'riding_state'                                 ,
    'rotatable'                                    ,
    'selected'                                     ,
    'selected_gun_index'                           ,
    'shooting_state'                               ,
    'tags'                                         ,
    'tick_of_last_attack'                          ,
    'tick_of_last_damage'                          ,
    'walking_state'                                ,
    }

  -- local _copyable_combat_robot_properties = {
  --   'active'                                       ,
  --   -- 'bonus_mining_progress'                        ,
  --   'color'                                        ,
  --   'destructible'                                 ,
  --   'direction'                                    ,
  --   -- 'drop_target'                                  ,
  --   'energy'                                       ,
  --   -- 'fluidbox'                                     ,
  --   'force'                                        ,
  --   'health'                                       ,
  --   'last_user'                                    ,
  --   'minable'                                      ,
  --   -- 'mining_progress'                              ,
  --   'operable'                                     ,
  --   'orientation'                                  ,
  --   -- 'render_player'                                ,
  --   -- 'render_to_forces'                             ,
  --   'rotatable'                                    ,
  --   'tags'                                         ,
  --   'time_to_live'                                 ,
  --   }
    

  local function _safe_copy_inventory(source,target,method,copy_filters)
  
    method = method or 'transfer_stack'
    assert(({set_stack=true, transfer_stack=true})[method]
      , 'Incompatible method for inventory copy')
    
    if not target.is_empty() then --this function only handles 1:1-mapped transfer
      log:debug('Transfer failed: Target inventory is not empty.')
      return false end
  
    --is it even theoretically possible to transfer the inventory?
    if #source > #target then
      log:debugf('Inventory size %s ~= %s.', #source, #target)
      source.sort_and_merge()
      for i=#target+1, #source do
        if source[i].valid_for_read then --no, source is too full
          log:debug('Transfer failed: Target inventory is too small.')
          return false
          end
        end
      end
      
    --set filters
    if copy_filters then
      for i=1,#target do
        log:debug('copy filter', i)
        if not target.set_filter(i,source.get_filter(i)) then
          log:debug('Transfer failed: Could not set filter on target.')
          return false
          end
        end
      end
    
    --try to transfer items (until one stack can't be transferred or it's all done)
    local i = 0
    while i < #target do
      i = i+1
      log:debug('try transfer stack',i)
      if not target[i][method](source[i]) then
        log:debug('Transfer failed: Reverting raw inventory transfer')
        for j=i,1,-1 do
          assert(source[i][method](target[i]), 'Reverting failed.')
          end
        return false
        end
      end

    log:debug('Transfer succeeded.')
    return true
    end

    
  local function _safe_copy_character_inventories(source,target)
    local inventories = { -- (index = has_filters)
      {defines.inventory.character_main    , true },
      {defines.inventory.character_guns    , true },
      {defines.inventory.character_ammo    , true },
      {defines.inventory.character_armor   , false}, -- armor last (slot bonus)
      -- {defines.inventory.character_vehicle , true },
      {defines.inventory.character_trash   , false},
      }
    local i = 0
    while i < #inventories do
      log:debug('try transfer inventory',i)
      i = i+1
      local s = source.get_inventory(inventories[i][1])
      local t = target.get_inventory(inventories[i][1])
      if not _safe_copy_inventory(s,t,'transfer_stack',inventories[i][2]) then
        log:debug('reverting character inventory transfer')
        for j=1,1,-1 do
          local s = source.get_inventory(inventories[j][1])
          local t = target.get_inventory(inventories[j][1])
          _safe_copy_inventory(t,s,'transfer_stack',inventories[j][2])
          end
        return false
        end
      end
    return true
    end

  local function _copy_basic_character_properties(source,target)
    for _,k in pairs(_copyable_character_properties) do
      log:debug('Copy: ',k)
      target[k] = source[k]
      end
    end
    
  local function _copy_special_character_properties(source,target)
  
    -- target[({[true]='enable_flashlight', [false]='disable_flashlight'
      -- })[source.is_flashlight_enabled()]]()
      
    if source.is_flashlight_enabled () -- on by default
      then target.enable_flashlight ()
      else target.disable_flashlight() end
    
  
    -- if not source.is_flashlight_enabled() then target.disable_flashlight() end -- on by default
  
    -- local _
    -- _ = source.is_flashlight_enabled() and target.
    
    
    end
    
    
  -- @tparam LuaEntity source character
  -- @tparam LuaEntity target character
  local function _copy_logistic_slot_layout(source,target)
    if source.force.character_logistic_requests then --can't touch any of these if not.
      local source_filters
        = source.get_logistic_point(
        defines.logistic_member_index.character_requester).filters
      for _, filter in ntuples(2, source_filters) do
        target.set_personal_logistic_slot(
          filter.index, source.get_personal_logistic_slot(filter.index))
        end
      end
    end
    
  -- as of base 1.0.0 the engine does not seem to support 
  -- reassigning robots to a new character so they are recreated
  local function _copy_combat_robots(source,target)
    
    for _, robot in pairs(source.following_robots) do
      robot.combat_robot_owner = target
      end
    
    -- if true then return end
    -- 
    -- --@future: engine support added in 1.1+
    -- --https://forums.factorio.com/viewtopic.php?f=65&t=89285
    -- local create = source.surface.create_entity
    -- for _,old_robot in pairs(source.following_robots) do
    --   local new_robot = create{
    --     name = old_robot.name,
    --     position = old_robot.position,
    --     target = target, -- must follow new character
    --     raise_built = true,
    --     }
    --   if new_robot.valid then --let's hope nobody is deleting stuff
    --     for _,k in pairs(copyable_combat_robot_properties) do
    --       new_robot[k] = old_robot[k]
    --       end
    --     old_robot.destroy{raise_destroy=true}
    --     end
    --   end
    end
    
    
  -- @tparam LuaEntity entity character
  local function _get_armor_inventory_bonus(entity)
    local inv = entity.get_inventory(defines.inventory.character_armor)
    if inv and inv[1].valid_for_read then
      return inv[1].prototype.inventory_size_bonus
      end
    return 0 end
    
    
    
  local function _store_cursor_stack(p)
    if p.cursor_stack and p.cursor_stack.valid_for_read then
      local loc = p.hand_location
      local inv = game.create_inventory(1)
      inv[1].transfer_stack(p.cursor_stack)
      return {inv = inv, loc = loc, p = p}
      end
    end
    
  local function _restore_cursor_stack(obj)
    if obj then
      assert(obj.p.clear_cursor())
      obj.p.cursor_stack.transfer_stack(obj.inv[1])
      obj.p.hand_location = obj.loc
      obj.inv.destroy()
      end
    end
    
  ----------
  -- Attaches a new character to a player if possible.
  --
  -- If the player has no character then a new one will be attached. 
  -- If the player has a character then all inventories, logistic requests, etc.
  -- will be copied to the new character before the old one is destroyed.
  -- 
  -- If the target prototype does not have enough inventory slots, logistic slots, 
  -- etcpp, or the swapping fails for some other reason the original character
  -- will be kept as is.
  -- 
  -- @tparam LuaPlayer p
  -- @tparam string prototype_name Name of a player character prototype.
  -- @treturn boolean If the swap was successful.
  -- @function Player.try_swap_character
  --
  function Player.try_swap_character(p, prototype_name)
    verify(p, 'LuaPlayer')
    if prototype_name == nil then return false end
    verify(prototype_name, 'str')
    local prototype = assert(game.entity_prototypes[prototype_name])
    assert(prototype.type == 'character')
    --
    local target = p.surface.create_entity{
      name        = prototype_name ,
      position    = p.position,
      raise_built = false     ,
      force       = p.force   ,
      }
    --
    local source = p.character
    if not source then
      p.character = target
      return true end
    
    if source.vehicle then
      log:debug('Can not swap skin while riding a vehicle')
      return false end

      
    if target then
    
      target.associated_player = p -- doesn't seem to have any effect?
      
      --set inventories bonusses etc before inventory transfer!
      _copy_basic_character_properties  (source,target)
      _copy_logistic_slot_layout        (source,target)
      _copy_special_character_properties(source,target)
      
      -- Temporarily fake armor bonus before armor transfer.
      local bonus = _get_armor_inventory_bonus(source)
      Table.add(target, {'character_inventory_slots_bonus'}, bonus)
      
      if _safe_copy_character_inventories(source,target) then
        _copy_combat_robots(source,target)
        --
        local temp_cs = _store_cursor_stack(p)
        p.character = target
        _restore_cursor_stack(temp_cs)
        --
        -- Remove temporary bonus.
        Table.add(target, {'character_inventory_slots_bonus'}, -bonus)
        --
        source.destroy()
      else
        log:warn('SKIN SWAPPING INVENTORY TRANSFER FAILED!')
        _restore_cursor_stack(temp_cs)
        target.destroy()
        return false
        end
      
    else
      log:warn('Failed to create new character skin entity')
      return false
      end
      
    return true
    end --try_swap_skin
    
  
  end



-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Player') end
return function() return Player,_Player,_uLocale end
