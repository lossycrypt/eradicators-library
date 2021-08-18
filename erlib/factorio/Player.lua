-- (c) eradicator a.k.a lossycrypt, 2017-2020, not seperately licensable

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

local stop        = elreq('erlib/lua/Error'     )().Stopper 'Player'

-- local Stacktrace = elreq('erlib/factorio/Stacktrace')()

local Verificate = elreq('erlib/lua/Verificate')()
-- local Verify           , Verify_Or
    -- = Verificate.verify, Verificate.verify_or

-- local Tool       = elreq('erlib/lua/Tool'      )()
    
local Table      = elreq('erlib/lua/Table'     )()
-- local Array      = elreq('erlib/lua/Array'     )()
-- local Set        = elreq('erlib/lua/Set'       )()

-- local Compose    = elreq('erlib/lua/Meta/Compose')()
-- local L          = elreq('erlib/lua/Lambda'    )()

local Memoize = elreq('erlib/lua/Meta/Memoize')()

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
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Player') end
return function() return Player,_Player,_uLocale end
