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
      or (Player.notify(p, {'cant-reach'}, entity.position) and false)
  end

  
----------
-- Creates a localized flying text for a player.
--
-- @tparam LuaPlayer p
-- @tparam LocalisedString text
-- @tparam Position position
--
function Player.notify(p, text, position)
  return p.create_local_flying_text {
    text     = text    ,
    position = position, --@future: default to selected or player itself?
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

  
-- -------------------------------------------------------------------------- --
-- End                                                                        --
-- -------------------------------------------------------------------------- --
do (STDOUT or log or print)('  Loaded → erlib.Player') end
return function() return Player,_Player,_uLocale end
